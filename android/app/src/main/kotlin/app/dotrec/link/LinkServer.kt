package app.dotrec.link

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.util.Log
import app.dotrec.entry.ConsentActivity
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStream
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.util.UUID
import kotlin.random.Random

/**
 * Серверная часть DotRec Link для телефона (FR-LNK-01..05).
 * Управляет локальным TCP-сокетом (USB 127.0.0.1 / Wi-Fi сопряжение по PIN).
 */
object LinkServer {
    private const val TAG = "DotRecLink"
    private const val PAIR_PIN_TTL_MS = 120_000L // 2 минуты

    data class ServerState(
        val status: String = "idle", // "idle", "listening", "connected", "streaming"
        val mode: String = "usb",    // "usb", "wifi"
        val pin: String = "",
        val pinTtlSec: Int = 0,
        val clientName: String = "",
        val streamActive: Boolean = false,
        val latencyMs: Int = 24,
    )

    private val _state = MutableStateFlow(ServerState())
    val state: StateFlow<ServerState> = _state.asStateFlow()

    @Volatile private var serverSocket: ServerSocket? = null
    @Volatile private var clientSocket: Socket? = null
    @Volatile private var clientOutput: OutputStream? = null
    @Volatile private var running = false

    private var currentPin = ""
    private var pinExpiresAt = 0L

    var onKeyframeRequested: (() -> Unit)? = null
    var onBitrateChanged: ((Int) -> Unit)? = null
    var onConsentRequested: (() -> Unit)? = null
    var onBlankScreenRequested: ((Boolean) -> Unit)? = null
    private var thermalListener: Any? = null

    @Synchronized
    fun start(context: Context, mode: String = "usb") {
        stop()
        running = true

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val pm = context.getSystemService(Context.POWER_SERVICE) as? android.os.PowerManager
            if (pm != null) {
                val listener = android.os.PowerManager.OnThermalStatusChangedListener { status ->
                    if (status >= android.os.PowerManager.THERMAL_STATUS_SEVERE) {
                        Log.w(TAG, "Thermal throttling triggered: level=$status")
                        onBitrateChanged?.invoke(8_000_000)
                    }
                }
                pm.addThermalStatusListener(context.mainExecutor, listener)
                thermalListener = listener
            }
        }
        var pin = ""
        if (mode == "wifi") {
            pin = (100000 + Random.nextInt(900000)).toString()
            currentPin = pin
            pinExpiresAt = SystemClock.elapsedRealtime() + PAIR_PIN_TTL_MS
        } else {
            currentPin = ""
            pinExpiresAt = 0L
        }

        _state.value = ServerState(
            status = "listening",
            mode = mode,
            pin = pin,
            pinTtlSec = if (mode == "wifi") 120 else 0,
        )

        Thread({
            try {
                val bindAddr = if (mode == "usb") {
                    InetAddress.getByName("127.0.0.1")
                } else {
                    InetAddress.getByName("0.0.0.0")
                }
                val ss = ServerSocket(LinkProtocol.PORT, 1, bindAddr)
                serverSocket = ss
                Log.d(TAG, "LinkServer listening on ${bindAddr.hostAddress}:${LinkProtocol.PORT} (mode=$mode)")

                while (running) {
                    val socket = try {
                        ss.accept()
                    } catch (_: Exception) {
                        break
                    }
                    socket.tcpNoDelay = true
                    handleClient(context, socket, mode)
                }
            } catch (e: Exception) {
                Log.e(TAG, "LinkServer socket error: $e")
            } finally {
                _state.value = ServerState(status = "idle")
            }
        }, "DotRecLinkServer").start()
    }

    private fun handleClient(context: Context, socket: Socket, mode: String) {
        try {
            clientSocket = socket
            val reader = BufferedReader(InputStreamReader(socket.getInputStream()))
            val out = socket.getOutputStream()
            clientOutput = out

            // 1. Читаем строку рукопожатия
            val line = reader.readLine() ?: return
            val req = JSONObject(line)
            val clientVersion = req.optInt("version", 0)
            if (clientVersion != LinkProtocol.PROTOCOL_VERSION) {
                val resp = JSONObject().apply {
                    put("protocol", "dotrec_link")
                    put("version", LinkProtocol.PROTOCOL_VERSION)
                    put("status", "version_mismatch")
                }
                out.write((resp.toString() + "\n").toByteArray())
                out.flush()
                socket.close()
                return
            }

            // 2. Проверка авторизации
            if (mode == "wifi") {
                val authObj = req.optJSONObject("auth")
                val enteredPin = authObj?.optString("value") ?: ""
                val now = SystemClock.elapsedRealtime()
                if (now > pinExpiresAt || enteredPin != currentPin) {
                    val resp = JSONObject().apply {
                        put("protocol", "dotrec_link")
                        put("status", "auth_failed")
                        put("reason", if (now > pinExpiresAt) "pin_expired" else "invalid_pin")
                    }
                    out.write((resp.toString() + "\n").toByteArray())
                    out.flush()
                    socket.close()
                    return
                }
            }

            val clientName = req.optString("client", "DesktopClient")
            _state.value = _state.value.copy(
                status = "connected",
                clientName = clientName,
            )

            // 3. Отправляем успешный ответ рукопожатия
            val resp = JSONObject().apply {
                put("protocol", "dotrec_link")
                put("version", LinkProtocol.PROTOCOL_VERSION)
                put("status", "ok")
                put("device", JSONObject().apply {
                    put("model", Build.MODEL)
                    put("manufacturer", Build.MANUFACTURER)
                    put("android_version", Build.VERSION.SDK_INT)
                })
                put("session", JSONObject().apply {
                    put("token", UUID.randomUUID().toString().replace("-", ""))
                    put("port", LinkProtocol.PORT)
                })
            }
            out.write((resp.toString() + "\n").toByteArray())
            out.flush()

            // 4. Поток чтения входящих команд
            while (running && !socket.isClosed) {
                val frame = LinkProtocol.readFrame(socket.getInputStream()) ?: break
                if (frame.type == LinkProtocol.TYPE_COMMAND) {
                    handleCommand(context, String(frame.payload, Charsets.UTF_8))
                }
            }
        } catch (e: Exception) {
            Log.d(TAG, "Client disconnected: $e")
        } finally {
            clientOutput = null
            runCatching { socket.close() }
            _state.value = _state.value.copy(status = "listening", clientName = "")
        }
    }

    private fun handleCommand(context: Context, jsonStr: String) {
        try {
            val json = JSONObject(jsonStr)
            when (json.optString("cmd")) {
                "request_keyframe" -> {
                    Log.d(TAG, "Command: request_keyframe")
                    onKeyframeRequested?.invoke()
                }
                "set_bitrate" -> {
                    val bps = json.optInt("bitrate_bps", 16000000)
                    Log.d(TAG, "Command: set_bitrate $bps")
                    onBitrateChanged?.invoke(bps)
                }
                "set_blank_screen" -> {
                    val enabled = json.optBoolean("enabled", false)
                    Log.d(TAG, "Command: set_blank_screen $enabled")
                    onBlankScreenRequested?.invoke(enabled)
                }
                "trigger_consent" -> {
                    Log.d(TAG, "Command: trigger_consent from desktop")
                    onConsentRequested?.invoke()
                    val it = Intent(context, ConsentActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    context.startActivity(it)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse command: $e")
        }
    }

    @Synchronized
    fun stop() {
        running = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && thermalListener != null) {
            runCatching {
                // remove listener
            }
            thermalListener = null
        }
        runCatching { clientSocket?.close() }
        runCatching { serverSocket?.close() }
        clientSocket = null
        serverSocket = null
        clientOutput = null
        _state.value = ServerState(status = "idle")
    }

    fun broadcastConfig(spsPps: ByteArray) {
        val out = clientOutput ?: return
        try {
            LinkProtocol.writeFrame(
                out,
                LinkProtocol.TYPE_CONFIG,
                LinkProtocol.FLAG_KEYFRAME,
                0L,
                spsPps,
            )
        } catch (e: Exception) {
            Log.w(TAG, "Failed to write config frame: $e")
        }
    }

    fun broadcastVideo(data: ByteArray, isKeyframe: Boolean, ptsUs: Long) {
        val out = clientOutput ?: return
        try {
            val flags = if (isKeyframe) LinkProtocol.FLAG_KEYFRAME else 0.toByte()
            LinkProtocol.writeFrame(
                out,
                LinkProtocol.TYPE_VIDEO,
                flags,
                ptsUs,
                data,
            )
        } catch (e: Exception) {
            Log.w(TAG, "Failed to write video frame: $e")
        }
    }

    fun broadcastAudio(data: ByteArray, ptsUs: Long) {
        val out = clientOutput ?: return
        try {
            LinkProtocol.writeFrame(
                out,
                LinkProtocol.TYPE_AUDIO,
                0.toByte(),
                ptsUs,
                data,
            )
        } catch (e: Exception) {
            Log.w(TAG, "Failed to write audio frame: $e")
        }
    }

    fun isClientConnected(): Boolean = clientOutput != null
}
