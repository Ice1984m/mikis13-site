package com.mikis13.gok

import android.annotation.SuppressLint
import android.app.Activity
import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import android.widget.ProgressBar
import android.widget.TextView

class MainActivity : Activity() {

    private lateinit var webView: WebView
    private lateinit var progressBar: ProgressBar
    private lateinit var errorText: TextView

    private val startUrl =
        "https://ice1984m.github.io/mikis13-site/goksites.html"

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val container = FrameLayout(this).apply {
            setBackgroundColor(Color.rgb(5, 8, 22))
        }

        webView = WebView(this).apply {
            setBackgroundColor(Color.rgb(5, 8, 22))
        }

        progressBar = ProgressBar(this)

        errorText = TextView(this).apply {
            text = """
                Mikis13 Gok kan niet worden geladen.

                Controleer je internetverbinding.
                Tik hier om opnieuw te proberen.
            """.trimIndent()

            setTextColor(Color.WHITE)
            textSize = 18f
            gravity = android.view.Gravity.CENTER
            visibility = View.GONE
            setPadding(40, 40, 40, 40)

            setOnClickListener {
                visibility = View.GONE
                progressBar.visibility = View.VISIBLE
                webView.reload()
            }
        }

        container.addView(
            webView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )

        container.addView(
            errorText,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )

        val progressLayout = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = android.view.Gravity.CENTER
        }

        container.addView(progressBar, progressLayout)
        setContentView(container)

        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            databaseEnabled = true
            cacheMode = WebSettings.LOAD_DEFAULT
            mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
            builtInZoomControls = false
            displayZoomControls = false
            allowFileAccess = false
            allowContentAccess = false
            userAgentString =
                "$userAgentString Mikis13GokAndroid/1.0"
        }

        webView.webChromeClient = object : WebChromeClient() {
            override fun onProgressChanged(
                view: WebView?,
                newProgress: Int
            ) {
                progressBar.visibility =
                    if (newProgress < 100) View.VISIBLE
                    else View.GONE
            }
        }

        webView.webViewClient = object : WebViewClient() {

            override fun shouldOverrideUrlLoading(
                view: WebView,
                request: WebResourceRequest
            ): Boolean {
                val host = request.url.host.orEmpty()

                return !(
                    host == "ice1984m.github.io" ||
                    host == "mikis13.nl" ||
                    host.endsWith(".mikis13.nl")
                )
            }

            override fun onPageFinished(
                view: WebView,
                url: String
            ) {
                progressBar.visibility = View.GONE
                errorText.visibility = View.GONE
            }

            @Deprecated("Oude Android-compatibiliteit")
            override fun onReceivedError(
                view: WebView?,
                errorCode: Int,
                description: String?,
                failingUrl: String?
            ) {
                progressBar.visibility = View.GONE
                errorText.visibility = View.VISIBLE
            }
        }

        if (savedInstanceState == null) {
            webView.loadUrl(startUrl)
        } else {
            webView.restoreState(savedInstanceState)
        }
    }

    @Deprecated("Oude Android-compatibiliteit")
    override fun onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack()
        } else {
            super.onBackPressed()
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        webView.saveState(outState)
        super.onSaveInstanceState(outState)
    }

    override fun onDestroy() {
        webView.stopLoading()
        webView.removeAllViews()
        webView.destroy()
        super.onDestroy()
    }
}
