package com.mikis13.stream

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.text.InputType
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

private data class StreamItem(val name: String, val url: String)

class MainActivity : Activity() {
    private val bg = Color.rgb(10, 6, 18)
    private val panel = Color.rgb(21, 14, 34)
    private val accent = Color.rgb(195, 117, 255)
    private val foreground = Color.rgb(248, 242, 255)
    private val muted = Color.rgb(183, 169, 201)
    private val channels = mutableListOf<StreamItem>()
    private val worker = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private lateinit var player: ExoPlayer
    private lateinit var playerView: PlayerView
    private lateinit var urlInput: EditText
    private lateinit var nameInput: EditText
    private lateinit var playlistInput: EditText
    private lateinit var channelList: LinearLayout
    private lateinit var status: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = bg
        window.navigationBarColor = bg
        player = ExoPlayer.Builder(this).build()
        restoreChannels()
        buildInterface()
        renderChannels()
        player.addListener(object : Player.Listener {
            override fun onPlayerError(error: PlaybackException) {
                status.text = "Stream niet beschikbaar. Controleer de URL, het formaat en je internetverbinding."
            }
            override fun onIsPlayingChanged(isPlaying: Boolean) {
                if (isPlaying) status.text = "Afspelen"
            }
        })
    }

    private fun buildInterface() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(bg)
        }
        val scroll = ScrollView(this)
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(18), dp(18), dp(18), dp(28))
        }
        scroll.addView(content)
        root.addView(scroll, LinearLayout.LayoutParams(-1, 0, 1f))

        content.addView(label("✦  MIKIS13 STREAM", 13, accent, true, top = 0))
        content.addView(label("Jouw streams. Jouw speler.", 27, foreground, true, top = 8))
        content.addView(label("Speel eigen MP3-streams en M3U/M3U8-playlists af.", 14, muted, false, top = 4, bottom = 15))

        playerView = PlayerView(this).apply {
            player = this@MainActivity.player
            useController = true
            setBackgroundColor(Color.BLACK)
        }
        content.addView(playerView, LinearLayout.LayoutParams(-1, dp(220)).apply { bottomMargin = dp(8) })
        status = label("Voeg een HTTPS-stream of playlist toe om te beginnen.", 13, accent, false, top = 2, bottom = 12)
        content.addView(status)

        content.addView(section("Directe stream"))
        nameInput = input("Naam, bijvoorbeeld Favoriete radio", InputType.TYPE_CLASS_TEXT)
        content.addView(nameInput, fieldParams())
        urlInput = input("HTTPS MP3- of M3U8-URL", InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_URI)
        content.addView(urlInput, fieldParams())
        val addRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
        addRow.addView(action("Stream toevoegen", true) { addDirectStream() }, LinearLayout.LayoutParams(-1, dp(48)))
        content.addView(addRow, fieldParams())

        content.addView(section("Playlist laden"))
        playlistInput = input("HTTPS-URL naar je M3U/M3U8-bestand", InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_URI)
        content.addView(playlistInput, fieldParams())
        val playlistRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        playlistRow.addView(action("Playlist-URL laden", false) { loadPlaylistUrl() }, LinearLayout.LayoutParams(0, dp(46), 1f).apply { marginEnd = dp(6) })
        playlistRow.addView(action("Bestand kiezen", false) { openPlaylistFile() }, LinearLayout.LayoutParams(0, dp(46), 1f).apply { marginStart = dp(6) })
        content.addView(playlistRow, fieldParams())

        val heading = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
        heading.addView(section("Mijn streams"), LinearLayout.LayoutParams(0, -2, 1f))
        heading.addView(action("Wissen", false) { clearChannels() }, LinearLayout.LayoutParams(-2, dp(40)))
        content.addView(heading, fieldParams())
        channelList = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        content.addView(channelList, fieldParams())

        content.addView(label("Deze speler levert geen zenders of muziek. Voeg alleen streams toe waarvoor je toestemming hebt. Je lijst wordt op dit apparaat bewaard.", 12, muted, false, top = 12))
        setContentView(root)
    }

    private fun addDirectStream() {
        val url = validHttps(urlInput.text.toString().trim())
        if (url == null) {
            status.text = "Vul een geldige HTTPS-stream-URL in."
            return
        }
        val name = nameInput.text.toString().trim().ifBlank { streamName(url) }
        addChannels(listOf(StreamItem(name, url)))
        nameInput.text.clear()
        urlInput.text.clear()
    }

    private fun loadPlaylistUrl() {
        val url = validHttps(playlistInput.text.toString().trim())
        if (url == null) {
            status.text = "Vul een geldige HTTPS-playlist-URL in."
            return
        }
        status.text = "Playlist downloaden…"
        worker.execute {
            try {
                val connection = URL(url).openConnection() as HttpURLConnection
                connection.connectTimeout = 15000
                connection.readTimeout = 20000
                connection.setRequestProperty("User-Agent", "Mikis13Stream/1.0")
                connection.instanceFollowRedirects = true
                connection.inputStream.use { input ->
                    val bytes = input.readNBytes(5 * 1024 * 1024 + 1)
                    if (bytes.size > 5 * 1024 * 1024) error("Playlist is te groot (maximaal 5 MB).")
                    val parsed = parseM3u(String(bytes, Charsets.UTF_8))
                    mainHandler.post {
                        if (parsed.isEmpty()) status.text = "Geen geldige HTTPS-streams gevonden."
                        else addChannels(parsed)
                    }
                }
                connection.disconnect()
            } catch (exception: Exception) {
                mainHandler.post { status.text = exception.message ?: "Playlist kon niet worden geladen." }
            }
        }
    }

    private fun openPlaylistFile() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("audio/x-mpegurl", "application/vnd.apple.mpegurl", "text/plain"))
        }
        startActivityForResult(intent, REQUEST_PLAYLIST)
    }

    @Deprecated("Compatibel met de minimale Android-versie")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_PLAYLIST || resultCode != RESULT_OK) return
        val uri = data?.data ?: return
        status.text = "Playlistbestand lezen…"
        worker.execute {
            try {
                val parsed = contentResolver.openInputStream(uri)?.use { input ->
                    val bytes = input.readNBytes(5 * 1024 * 1024 + 1)
                    if (bytes.size > 5 * 1024 * 1024) error("Playlist is te groot (maximaal 5 MB).")
                    parseM3u(String(bytes, Charsets.UTF_8))
                } ?: emptyList()
                mainHandler.post {
                    if (parsed.isEmpty()) status.text = "Geen geldige HTTPS-streams gevonden in dit bestand."
                    else addChannels(parsed)
                }
            } catch (exception: Exception) {
                mainHandler.post { status.text = exception.message ?: "Playlistbestand kon niet worden gelezen." }
            }
        }
    }

    private fun parseM3u(text: String): List<StreamItem> {
        val result = mutableListOf<StreamItem>()
        var pendingName = ""
        text.removePrefix("\uFEFF").lineSequence().forEach { raw ->
            val line = raw.trim()
            if (line.isEmpty()) return@forEach
            if (line.startsWith("#EXTINF:", ignoreCase = true)) {
                pendingName = line.substringAfterLast(',', "Stream").trim().ifBlank { "Stream" }
            } else if (!line.startsWith("#")) {
                val url = validHttps(line)
                if (url != null) result.add(StreamItem(pendingName.ifBlank { streamName(url) }, url))
                pendingName = ""
            }
        }
        return result
    }

    private fun addChannels(items: List<StreamItem>) {
        val known = channels.map { it.url }.toSet()
        val newItems = items.filter { it.url !in known }
        channels.addAll(newItems)
        saveChannels()
        renderChannels()
        status.text = if (newItems.isEmpty()) "Geen nieuwe geldige HTTPS-streams gevonden."
        else "${newItems.size} stream(s) toegevoegd."
    }

    private fun play(item: StreamItem) {
        val mediaItem = MediaItem.Builder().setUri(item.url).apply {
            if (item.url.substringBefore('?').endsWith(".m3u8", true)) setMimeType(MimeTypes.APPLICATION_M3U8)
        }.build()
        player.setMediaItem(mediaItem)
        player.prepare()
        player.playWhenReady = true
        status.text = "Stream laden: ${item.name}"
    }

    private fun renderChannels() {
        if (!::channelList.isInitialized) return
        channelList.removeAllViews()
        if (channels.isEmpty()) {
            channelList.addView(label("Je streamlijst is nog leeg.", 13, muted, false, top = 4))
            return
        }
        channels.forEachIndexed { index, item ->
            val row = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setBackgroundColor(panel)
                setPadding(dp(10), dp(5), dp(5), dp(5))
            }
            row.addView(action("▶  ${item.name}", false) { play(item) }, LinearLayout.LayoutParams(0, dp(46), 1f))
            row.addView(action("×", false) {
                channels.removeAt(index)
                saveChannels()
                renderChannels()
            }, LinearLayout.LayoutParams(dp(46), dp(46)))
            channelList.addView(row, LinearLayout.LayoutParams(-1, -2).apply { bottomMargin = dp(7) })
        }
    }

    private fun clearChannels() {
        channels.clear()
        player.stop()
        saveChannels()
        renderChannels()
        status.text = "Je streamlijst is van dit apparaat verwijderd."
    }

    private fun restoreChannels() {
        val json = getSharedPreferences(PREFS, MODE_PRIVATE).getString(CHANNELS_KEY, "[]") ?: "[]"
        runCatching {
            val array = JSONArray(json)
            for (i in 0 until array.length()) {
                val item = array.getJSONObject(i)
                val url = validHttps(item.optString("url")) ?: continue
                channels.add(StreamItem(item.optString("name", "Stream"), url))
            }
        }
    }

    private fun saveChannels() {
        val array = JSONArray()
        channels.forEach { array.put(JSONObject().put("name", it.name).put("url", it.url)) }
        getSharedPreferences(PREFS, MODE_PRIVATE).edit().putString(CHANNELS_KEY, array.toString()).apply()
    }

    private fun validHttps(value: String): String? {
        val uri = runCatching { Uri.parse(value) }.getOrNull() ?: return null
        return value.takeIf { uri.scheme.equals("https", true) && !uri.host.isNullOrBlank() }
    }

    private fun streamName(value: String): String = runCatching {
        Uri.parse(value).lastPathSegment?.substringBefore('?')?.takeIf { it.isNotBlank() } ?: "Stream"
    }.getOrDefault("Stream")

    private fun input(hintText: String, type: Int) = EditText(this).apply {
        hint = hintText
        inputType = type
        setSingleLine(true)
        textSize = 14f
        setTextColor(this@MainActivity.foreground)
        setHintTextColor(muted)
        setPadding(dp(12), 0, dp(12), 0)
        setBackgroundColor(panel)
    }

    private fun section(value: String) = label(value, 17, foreground, true, top = 10, bottom = 4)

    private fun label(value: String, size: Int, color: Int, bold: Boolean, top: Int, bottom: Int = 0) = TextView(this).apply {
        text = value
        textSize = size.toFloat()
        setTextColor(color)
        if (bold) setTypeface(typeface, android.graphics.Typeface.BOLD)
        setPadding(0, dp(top), 0, dp(bottom))
    }

    private fun action(value: String, primary: Boolean, click: () -> Unit) = Button(this).apply {
        text = value
        textSize = 13f
        isAllCaps = false
        setTextColor(if (primary) this@MainActivity.bg else this@MainActivity.foreground)
        setBackgroundColor(if (primary) accent else panel)
        setOnClickListener { click() }
    }

    private fun fieldParams() = LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(5); bottomMargin = dp(5) }
    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

    override fun onDestroy() {
        worker.shutdownNow()
        player.release()
        super.onDestroy()
    }

    companion object {
        private const val REQUEST_PLAYLIST = 413
        private const val PREFS = "mikis13-stream"
        private const val CHANNELS_KEY = "streams"
    }
}
