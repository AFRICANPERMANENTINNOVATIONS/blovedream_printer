package africa.permanentinnovations.bld_thermal_printer

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.lang.reflect.InvocationHandler
import java.lang.reflect.Method
import java.lang.reflect.Proxy

/**
 * Reflection-based bridge to the OEM `android.bld.PrintManager` service.
 *
 * The class is shipped only by the device firmware and is not in the AOSP
 * SDK, so it cannot be linked at compile time. We resolve every method at
 * runtime through reflection. If the host device is not a Blovedream
 * terminal, [open] (and any other call) throws an [IllegalStateException].
 */
internal class PrinterBridge(context: Context) {

    private val ctx = context.applicationContext

    private val pmClass: Class<*> by lazy {
        try {
            Class.forName("android.bld.PrintManager")
        } catch (t: Throwable) {
            throw IllegalStateException(
                "android.bld.PrintManager not found — this device is not a Blovedream terminal.",
                t,
            )
        }
    }

    private val listenerClass: Class<*> by lazy {
        Class.forName("android.bld.print.aidl.PrinterBinderListener")
    }

    private val pm: Any by lazy {
        val getDefault = pmClass.getMethod("getDefaultInstance", Context::class.java)
        getDefault.invoke(null, ctx)
            ?: error("PrintManager.getDefaultInstance returned null")
    }

    private var listenerProxy: Any? = null

    // ---- lifecycle -----------------------------------------------------------

    fun open(): Boolean = pmClass.getMethod("open").invoke(pm) as Boolean
    fun close(): Boolean = pmClass.getMethod("close").invoke(pm) as Boolean
    fun start() { pmClass.getMethod("start").invoke(pm) }
    fun reset(): Int = pmClass.getMethod("reset").invoke(pm) as Int
    fun getPrinterVer(): String? =
        pmClass.getMethod("getPrinterVer").invoke(pm) as String?

    // ---- configuration -------------------------------------------------------

    fun setFontSize(size: Int) {
        pmClass.getMethod("setFontSize", Int::class.javaPrimitiveType).invoke(pm, size)
    }
    fun getFontSize(): Int = pmClass.getMethod("getFontSize").invoke(pm) as Int

    fun setFontBold(bold: Boolean) {
        pmClass.getMethod("setFontBold", Boolean::class.javaPrimitiveType).invoke(pm, bold)
    }
    fun isFontBold(): Boolean = pmClass.getMethod("isFontBold").invoke(pm) as Boolean

    fun setUnderLine(under: Boolean) {
        pmClass.getMethod("setUnderLine", Boolean::class.javaPrimitiveType).invoke(pm, under)
    }
    fun isUnderLine(): Boolean = pmClass.getMethod("isUnderLine").invoke(pm) as Boolean

    fun setReverse(reverse: Boolean) {
        pmClass.getMethod("setReverse", Boolean::class.javaPrimitiveType).invoke(pm, reverse)
    }
    fun isReverse(): Boolean = pmClass.getMethod("isReverse").invoke(pm) as Boolean

    fun setDensity(density: Int) {
        pmClass.getMethod("setDensity", Int::class.javaPrimitiveType).invoke(pm, density)
    }
    fun getDensity(): Int = pmClass.getMethod("getDensity").invoke(pm) as Int

    fun setLineSpacing(spacing: Float) {
        pmClass.getMethod("setLineSpacing", Float::class.javaPrimitiveType).invoke(pm, spacing)
    }
    fun getLineSpacing(): Float = pmClass.getMethod("getLineSpacing").invoke(pm) as Float

    fun setBlackLabel(enabled: Boolean) {
        pmClass.getMethod("setBlackLabel", Boolean::class.javaPrimitiveType).invoke(pm, enabled)
    }
    fun isBlackLabel(): Boolean = pmClass.getMethod("isBlackLabel").invoke(pm) as Boolean

    fun setFeedPaperSpace(space: Int) {
        pmClass.getMethod("setFeedPaperSpace", Int::class.javaPrimitiveType).invoke(pm, space)
    }
    fun getFeedPaperSpace(): Int = pmClass.getMethod("getFeedPaperSpace").invoke(pm) as Int

    fun setUnwindPaperLen(len: Int) {
        pmClass.getMethod("setUnwindPaperLen", Int::class.javaPrimitiveType).invoke(pm, len)
    }
    fun getUnwindPaperLen(): Int = pmClass.getMethod("getUnwindPaperLen").invoke(pm) as Int

    // ---- commands ------------------------------------------------------------

    fun addText(align: Int, fontSize: Int, bold: Boolean, underline: Boolean, text: String) {
        val m = pmClass.getMethod(
            "addText",
            Int::class.javaPrimitiveType,
            Int::class.javaPrimitiveType,
            Boolean::class.javaPrimitiveType,
            Boolean::class.javaPrimitiveType,
            String::class.java,
        )
        m.invoke(pm, align, fontSize, bold, underline, text)
    }

    fun addBarcode(type: Int, height: Int, content: String, hri: Int, unitWidth: Int) {
        val m = pmClass.getMethod(
            "addBarcode",
            Int::class.javaPrimitiveType,
            Int::class.javaPrimitiveType,
            String::class.java,
            Int::class.javaPrimitiveType,
            Int::class.javaPrimitiveType,
        )
        m.invoke(pm, type, height, content, hri, unitWidth)
    }

    fun addQrCode(align: Int, size: Int, content: String) {
        val m = pmClass.getMethod(
            "addQRCode",
            Int::class.javaPrimitiveType,
            Int::class.javaPrimitiveType,
            String::class.java,
        )
        m.invoke(pm, align, size, content)
    }

    fun addImage(align: Int, bitmap: Bitmap) {
        val m = pmClass.getMethod(
            "addImage",
            Int::class.javaPrimitiveType,
            Bitmap::class.java,
        )
        m.invoke(pm, align, bitmap)
    }

    fun addImageFile(align: Int, path: String) {
        val m = pmClass.getMethod(
            "addImageFile",
            Int::class.javaPrimitiveType,
            String::class.java,
        )
        m.invoke(pm, align, path)
    }

    fun addImageBytes(align: Int, bytes: ByteArray) {
        val bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            ?: error("Failed to decode bitmap bytes")
        addImage(align, bmp)
    }

    fun addLineFeed(lines: Int) {
        pmClass.getMethod("addLineFeed", Int::class.javaPrimitiveType).invoke(pm, lines)
    }

    // ---- listener ------------------------------------------------------------

    fun setListener(callbacks: PrinterCallbacks) {
        removeListener()
        val proxy = Proxy.newProxyInstance(
            listenerClass.classLoader,
            arrayOf(listenerClass),
            ListenerHandler(callbacks),
        )
        pmClass.getMethod("addPrintListener", listenerClass).invoke(pm, proxy)
        listenerProxy = proxy
        getPrinterVer()?.let { callbacks.onVersion(it) }
    }

    fun removeListener() {
        val proxy = listenerProxy ?: return
        try {
            pmClass.getMethod("removePrintListener", listenerClass).invoke(pm, proxy)
        } catch (_: Throwable) {
            // ignore — best-effort cleanup
        }
        listenerProxy = null
    }

    // ---- system property ----------------------------------------------------

    fun getSupportPrint(): Int = readSystemPropertyInt("ro.blovedream_support_print", 0)

    interface PrinterCallbacks {
        fun onPrintCallback(errorCode: Int)
        fun onVersion(version: String)
    }

    private class ListenerHandler(private val cb: PrinterCallbacks) : InvocationHandler {
        override fun invoke(proxy: Any?, method: Method, args: Array<out Any?>?): Any? {
            return when (method.name) {
                "onPrintCallback" -> {
                    val code = (args?.firstOrNull() as? Int) ?: 0xff
                    cb.onPrintCallback(code)
                    null
                }
                "onVersion" -> {
                    val v = (args?.firstOrNull() as? String).orEmpty()
                    cb.onVersion(v)
                    null
                }
                "asBinder" -> null
                "toString" -> "BlovedreamPrinterListenerProxy"
                "hashCode" -> System.identityHashCode(proxy)
                "equals" -> proxy === args?.firstOrNull()
                else -> null
            }
        }
    }

    private fun readSystemPropertyInt(key: String, def: Int): Int {
        return try {
            val cls = Class.forName("android.os.SystemProperties")
            val m = cls.getMethod("getInt", String::class.java, Int::class.javaPrimitiveType)
            (m.invoke(null, key, def) as Int)
        } catch (_: Throwable) {
            def
        }
    }
}
