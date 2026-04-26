package africa.permanentinnovations.bld_thermal_printer

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class BlovedreamPrinterPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    private companion object {
        const val METHOD_CHANNEL = "africa.permanentinnovations/blovedream_printer"
        const val EVENT_CHANNEL = "africa.permanentinnovations/blovedream_printer/events"
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var bridge: PrinterBridge
    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val ctx: Context = binding.applicationContext
        bridge = PrinterBridge(ctx)
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        try { bridge.removeListener() } catch (_: Throwable) {}
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "open" -> { bridge.open(); result.success(null) }
                "close" -> { bridge.close(); result.success(null) }
                "start" -> { bridge.start(); result.success(null) }
                "reset" -> { bridge.reset(); result.success(null) }
                "getVersion" -> result.success(bridge.getPrinterVer())
                "getSupportPrint" -> result.success(bridge.getSupportPrint())

                "setFontSize" -> { bridge.setFontSize(call.intArg("size")); result.success(null) }
                "getFontSize" -> result.success(bridge.getFontSize())
                "setBold" -> { bridge.setFontBold(call.boolArg("bold")); result.success(null) }
                "isBold" -> result.success(bridge.isFontBold())
                "setUnderline" -> { bridge.setUnderLine(call.boolArg("underline")); result.success(null) }
                "isUnderline" -> result.success(bridge.isUnderLine())
                "setReverse" -> { bridge.setReverse(call.boolArg("reverse")); result.success(null) }
                "isReverse" -> result.success(bridge.isReverse())
                "setDensity" -> { bridge.setDensity(call.intArg("density")); result.success(null) }
                "getDensity" -> result.success(bridge.getDensity())
                "setLineSpacing" -> {
                    bridge.setLineSpacing(call.doubleArg("spacing").toFloat()); result.success(null)
                }
                "getLineSpacing" -> result.success(bridge.getLineSpacing().toDouble())
                "setBlackLabel" -> {
                    bridge.setBlackLabel(call.boolArg("enabled")); result.success(null)
                }
                "isBlackLabel" -> result.success(bridge.isBlackLabel())
                "setFeedPaperSpace" -> {
                    bridge.setFeedPaperSpace(call.intArg("space")); result.success(null)
                }
                "getFeedPaperSpace" -> result.success(bridge.getFeedPaperSpace())
                "setUnwindPaperLen" -> {
                    bridge.setUnwindPaperLen(call.intArg("length")); result.success(null)
                }
                "getUnwindPaperLen" -> result.success(bridge.getUnwindPaperLen())

                "printText" -> {
                    bridge.addText(
                        call.intArg("align"),
                        call.intArg("fontSize"),
                        call.boolArg("bold"),
                        call.boolArg("underline"),
                        call.argument<String>("text") ?: "",
                    )
                    result.success(null)
                }
                "printBarcode" -> {
                    bridge.addBarcode(
                        call.intArg("type"),
                        call.intArg("height"),
                        call.argument<String>("content") ?: "",
                        call.intArg("hri"),
                        call.intArg("unitWidth"),
                    )
                    result.success(null)
                }
                "printQr" -> {
                    bridge.addQrCode(
                        call.intArg("align"),
                        call.intArg("size"),
                        call.argument<String>("content") ?: "",
                    )
                    result.success(null)
                }
                "printBitmapPath" -> {
                    bridge.addImageFile(
                        call.intArg("align"),
                        call.argument<String>("path") ?: "",
                    )
                    result.success(null)
                }
                "printBitmapBytes" -> {
                    val bytes = call.argument<ByteArray>("bytes") ?: ByteArray(0)
                    bridge.addImageBytes(call.intArg("align"), bytes)
                    result.success(null)
                }
                "lineFeed" -> { bridge.addLineFeed(call.intArg("lines")); result.success(null) }
                "goToNextMark" -> {
                    bridge.setFeedPaperSpace(call.intArg("feedSpace"))
                    bridge.start()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        } catch (t: Throwable) {
            result.error("BLD_ERROR", t.message, t.stackTraceToString())
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        bridge.setListener(object : PrinterBridge.PrinterCallbacks {
            override fun onPrintCallback(errorCode: Int) {
                mainHandler.post {
                    eventSink?.success(mapOf("type" to "onPrintCallback", "errorCode" to errorCode))
                }
            }

            override fun onVersion(version: String) {
                mainHandler.post {
                    eventSink?.success(mapOf("type" to "onVersion", "version" to version))
                }
            }
        })
    }

    override fun onCancel(arguments: Any?) {
        try { bridge.removeListener() } catch (_: Throwable) {}
        eventSink = null
    }

    // -- helpers --------------------------------------------------------------

    private fun MethodCall.intArg(name: String): Int =
        (argument<Number>(name) ?: error("missing arg $name")).toInt()

    private fun MethodCall.boolArg(name: String): Boolean =
        argument<Boolean>(name) ?: error("missing arg $name")

    private fun MethodCall.doubleArg(name: String): Double =
        (argument<Number>(name) ?: error("missing arg $name")).toDouble()
}
