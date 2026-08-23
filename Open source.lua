require "import"
import "android.widget.*"
import "android.view.*"
import "android.app.AlertDialog"
import "android.media.MediaPlayer"
import "android.speech.tts.TextToSpeech"
import "java.util.Locale"
import "android.content.Intent"
import "android.net.Uri"
import "android.content.pm.PackageManager"
import "android.content.pm.ResolveInfo"
import "android.text.TextWatcher"
import "android.content.SharedPreferences"
import "android.text.InputFilter"
import "android.widget.Toast"
import "android.graphics.drawable.GradientDrawable"

-- ===================== SHARED PREFERENCES =====================
local prefs = activity.getSharedPreferences("SnakeLadderSettings", activity.MODE_PRIVATE)

-- ===================== GLOBAL SETTINGS =====================
soundRoll = true
soundMove = true
soundLadder = true
soundSnake = true

rollVol = 80
moveVol = 80
ladderVol = 80
snakeVol = 80

ttsEnabled = true
winTarget = 100

commentaryLangCode = "en"
selectedTtsEngine = nil
tts = nil

registered = false
username = "Player"
privacyAccepted = false

-- ===================== STATS =====================
stats = {
    playerName = "Player",
    wins = 0,
    losses = 0,
    snakeBites = 0,
    ladderClimbs = 0,
    totalGames = 0
}

-- ===================== GAME STATE =====================
gameState = {
    players = {},
    positions = {},
    currentPlayer = 0,
    gameMode = "",
    isComputerTurn = false,
    isGameOver = false,
}

-- ===================== LOAD SETTINGS =====================
function loadSettings()
    soundRoll = prefs.getBoolean("soundRoll", true)
    soundMove = prefs.getBoolean("soundMove", true)
    soundLadder = prefs.getBoolean("soundLadder", true)
    soundSnake = prefs.getBoolean("soundSnake", true)

    rollVol = prefs.getInt("rollVol", 80)
    moveVol = prefs.getInt("moveVol", 80)
    ladderVol = prefs.getInt("ladderVol", 80)
    snakeVol = prefs.getInt("snakeVol", 80)

    ttsEnabled = prefs.getBoolean("ttsEnabled", true)
    commentaryLangCode = prefs.getString("commentaryLangCode", "en")
    selectedTtsEngine = prefs.getString("selectedTtsEngine", nil)
    if selectedTtsEngine == "" then selectedTtsEngine = nil end

    registered = prefs.getBoolean("registered", false)
    username = prefs.getString("username", "Player")
    privacyAccepted = prefs.getBoolean("privacyAccepted", false)
    stats.playerName = username

    stats.wins = prefs.getInt("wins", 0)
    stats.losses = prefs.getInt("losses", 0)
    stats.snakeBites = prefs.getInt("snakeBites", 0)
    stats.ladderClimbs = prefs.getInt("ladderClimbs", 0)
    stats.totalGames = prefs.getInt("totalGames", 0)

    gameState.players = {username}
    gameState.positions = {0}
end

-- ===================== SAVE SETTINGS =====================
function saveSettings()
    local editor = prefs.edit()
    editor.putBoolean("soundRoll", soundRoll)
    editor.putBoolean("soundMove", soundMove)
    editor.putBoolean("soundLadder", soundLadder)
    editor.putBoolean("soundSnake", soundSnake)

    editor.putInt("rollVol", rollVol)
    editor.putInt("moveVol", moveVol)
    editor.putInt("ladderVol", ladderVol)
    editor.putInt("snakeVol", snakeVol)

    editor.putBoolean("ttsEnabled", ttsEnabled)
    editor.putString("commentaryLangCode", commentaryLangCode)
    if selectedTtsEngine then
        editor.putString("selectedTtsEngine", selectedTtsEngine)
    else
        editor.putString("selectedTtsEngine", "")
    end
    editor.putBoolean("registered", registered)
    editor.putString("username", username)
    editor.putBoolean("privacyAccepted", privacyAccepted)

    editor.putInt("wins", stats.wins)
    editor.putInt("losses", stats.losses)
    editor.putInt("snakeBites", stats.snakeBites)
    editor.putInt("ladderClimbs", stats.ladderClimbs)
    editor.putInt("totalGames", stats.totalGames)

    editor.apply()
end

-- ===================== RESET ALL SETTINGS (LOGOUT) =====================
function resetAllSettings()
    soundRoll = true
    soundMove = true
    soundLadder = true
    soundSnake = true
    rollVol = 80
    moveVol = 80
    ladderVol = 80
    snakeVol = 80
    ttsEnabled = true
    commentaryLangCode = "en"
    selectedTtsEngine = nil
    registered = false
    username = "Player"
    stats.playerName = username
    stats.wins = 0
    stats.losses = 0
    stats.snakeBites = 0
    stats.ladderClimbs = 0
    stats.totalGames = 0
    gameState.players = {username}
    gameState.positions = {0}
    if tts then
        pcall(function() tts.shutdown() end)
        tts = nil
    end
    initTts(nil)
    saveSettings()
end

-- ===================== TIME GREETING =====================
function getTimeGreeting()
    local t = os.date("*t")
    local hour = t.hour
    if hour >= 5 and hour < 12 then
        return "Good Morning"
    elseif hour >= 12 and hour < 17 then
        return "Good Afternoon"
    else
        return "Good Evening"
    end
end

-- ===================== LOCALIZATION =====================
local translations = {
    en = {
        rolled = "rolled a",
        moved_to = "moved to",
        climbed_ladder = "climbed a ladder to",
        bitten_snake = "got bitten by snake to",
        overshot = "overshot! You stay at",
        wins_game = "wins the game!",
        you_win = "You win!",
        you_lose = "You lose!",
        player = "Player",
        computer = "Computer",
        roll_disabled = "Roll button is disabled or not available.",
        tts_engine_changed = "TTS engine changed successfully.",
        commentary_changed = "Commentary language changed to %s",
        settings_saved = "Settings saved.",
        positions = "%s is at position %d. %s is at position %d.",
        welcome_back = "Welcome back, %s!",
        enter_username = "Enter your username (no spaces):",
        username_error = "Username cannot contain spaces.",
        registration_success = "Registration successful! Welcome, %s.",
        username_changed = "Username changed to %s.",
        logged_out = "Logged out successfully.",
        select_mode = "Select Game Mode",
        pass_play = "Pass and Play",
        play_computer = "Play with Computer",
        play_online = "Play with Online Players",
        coming_soon = "This feature is coming soon",
        player_setup = "Player Setup",
        player2_name = "Player 2 Name (compulsory)",
        player3_name = "Player 3 Name (optional)",
        player4_name = "Player 4 Name (optional)",
        start_passing = "Start Passing Game",
        please_enter_p2 = "Please enter Player 2 name.",
        turn_message = "%s's Turn",
        extra_turn = "You got 6! Extra turn!",
    },
    hi = {
        rolled = "ने पासा फेंका",
        moved_to = "पहुँच गए",
        climbed_ladder = "सीढ़ी चढ़कर पहुँचे",
        bitten_snake = "साँप ने काटा, पहुँचे",
        overshot = "आगे निकल गए! आप रुके",
        wins_game = "ने गेम जीत लिया!",
        you_win = "आप जीत गए!",
        you_lose = "आप हार गए!",
        player = "खिलाड़ी",
        computer = "कंप्यूटर",
        roll_disabled = "रोल बटन अक्षम है या उपलब्ध नहीं।",
        tts_engine_changed = "टीटीएस इंजन बदल गया।",
        commentary_changed = "कमेंट्री भाषा बदलकर %s कर दी गई",
        settings_saved = "सेटिंग्स सेव हो गईं।",
        positions = "%s %d पर है। %s %d पर है।",
        welcome_back = "वापसी पर स्वागत है, %s!",
        enter_username = "अपना उपयोगकर्ता नाम दर्ज करें (कोई स्पेस नहीं):",
        username_error = "उपयोगकर्ता नाम में स्पेस नहीं हो सकते।",
        registration_success = "पंजीकरण सफल! स्वागत है, %s।",
        username_changed = "उपयोगकर्ता नाम बदलकर %s कर दिया गया।",
        logged_out = "सफलतापूर्वक लॉग आउट।",
        select_mode = "गेम मोड चुनें",
        pass_play = "पास एंड प्ले",
        play_computer = "कंप्यूटर के साथ खेलें",
        play_online = "ऑनलाइन खिलाड़ियों के साथ",
        coming_soon = "यह फीचर जल्द आ रहा है",
        player_setup = "खिलाड़ी सेटअप",
        player2_name = "खिलाड़ी 2 का नाम (अनिवार्य)",
        player3_name = "खिलाड़ी 3 का नाम (वैकल्पिक)",
        player4_name = "खिलाड़ी 4 का नाम (वैकल्पिक)",
        start_passing = "पासिंग गेम शुरू करें",
        please_enter_p2 = "कृपया खिलाड़ी 2 का नाम दर्ज करें।",
        turn_message = "%s की बारी",
        extra_turn = "आपको 6 मिला! अतिरिक्त बारी!",
    }
}

function _(key, ...)
    local lang = commentaryLangCode
    if not translations[lang] then lang = "en" end
    local str = translations[lang][key] or translations["en"][key] or key
    return string.format(str, ...)
end

-- ===================== TTS INITIALIZATION =====================
function initTts(enginePackage)
    if tts then
        pcall(function() tts.shutdown() end)
        tts = nil
    end
    if not ttsEnabled then return end

    local listener = {onInit=function(status)
        if status == TextToSpeech.SUCCESS then
            local loc = Locale.forLanguageTag(commentaryLangCode)
            if loc == nil or loc.getLanguage() == "" then
                loc = Locale.US
            end
            local result = tts.setLanguage(loc)
            if result == TextToSpeech.LANG_MISSING_DATA or result == TextToSpeech.LANG_NOT_SUPPORTED then
                tts.setLanguage(Locale.getDefault())
            end
            speak(_("tts_engine_changed"))
        end
    end}

    if enginePackage then
        tts = TextToSpeech(activity, listener, enginePackage)
    else
        tts = TextToSpeech(activity, listener)
    end
end

loadSettings()
initTts(selectedTtsEngine)

function speak(text)
    if tts ~= nil and ttsEnabled then
        pcall(function()
            tts.speak(text, TextToSpeech.QUEUE_FLUSH, nil)
        end)
    end
end

-- ===================== PATHS =====================
local base = "/sdcard/解说/Tools/Snake and ladder/sounds/"
local sRoll = base .. "rolldice.mp3"
local sMove = base .. "move.aac"
local sLadder = base .. "ladder.mp3"
local sSnake = base .. "snake.mp3"

local snakes = {[16]=6, [47]=26, [49]=11, [56]=53, [62]=19, [64]=60, [87]=24, [93]=73, [95]=75, [98]=78}
local ladders = {[1]=38, [4]=14, [9]=31, [21]=42, [28]=84, [36]=44, [51]=67, [71]=91, [80]=100}

-- ===================== SOUND ENGINE =====================
function fileExists(path)
    local f = io.open(path, "r")
    if f then f:close(); return true else return false end
end

function playSound(path, soundType)
    local enabled = true
    local vol = 80
    if soundType == "roll" then
        enabled = soundRoll
        vol = rollVol
    elseif soundType == "move" then
        enabled = soundMove
        vol = moveVol
    elseif soundType == "ladder" then
        enabled = soundLadder
        vol = ladderVol
    elseif soundType == "snake" then
        enabled = soundSnake
        vol = snakeVol
    end
    if not enabled then return end
    if not fileExists(path) then return end

    local mp = MediaPlayer()
    pcall(function()
        mp.setDataSource(path)
        mp.prepare()
        mp.setVolume(vol/100, vol/100)
        mp.start()
        mp.setOnCompletionListener({onCompletion=function(m) m.release() end})
    end)
end

function playStepSounds(n)
    for i=1, n do
        task(i*300, function()
            playSound(sMove, "move")
        end)
    end
end

-- ===================== GESTURE DETECTOR =====================
lastSwipeTime = 0
lastSwipeDir = ""

function setupGestureListener(view, isGame)
    local detector = GestureDetector(activity, {
        onDown = function(e) return false end,
        onFling = function(e1, e2, velocityX, velocityY)
            local diffX = e1.getX() - e2.getX()
            local diffY = e1.getY() - e2.getY()
            local absX = math.abs(diffX)
            local absY = math.abs(diffY)
            local dir = ""
            if absX > absY then
                if diffX > 0 then dir = "left" else dir = "right" end
            else
                if diffY > 0 then dir = "up" else dir = "down" end
            end

            local now = System.currentTimeMillis()
            if now - lastSwipeTime < 500 and lastSwipeDir == dir then
                if not isGame then
                    if dir == "left" then
                        editName()
                    elseif dir == "right" then
                        logout()
                    end
                end
                lastSwipeTime = 0
                lastSwipeDir = ""
                return true
            else
                lastSwipeTime = now
                lastSwipeDir = dir
                if absX > absY then
                    if diffX > 0 then
                        if isGame then showPlayerPositions() end
                    else
                        if isGame then exitGame() end
                    end
                else
                    if diffY < 0 then
                        if isGame then performRoll() end
                    else
                        confirmCloseApp()
                    end
                end
                return true
            end
        end
    })
    view.setOnTouchListener({onTouch=function(v, event)
        return detector.onTouchEvent(event)
    end})
    return detector
end

-- ===================== GAME ACTIONS =====================
roll_btn = nil
status_tv = nil
target_label = nil
status_texts = {}

function performRoll()
    if roll_btn and roll_btn.isEnabled() then
        roll_btn.performClick()
    else
        speak(_("roll_disabled"))
    end
end

function showPlayerPositions()
    local msg = ""
    for i, name in ipairs(gameState.players) do
        local pos = gameState.positions[i] or 0
        msg = msg .. name .. " is at position " .. pos .. ". "
    end
    speak(msg)
    AlertDialog.Builder(activity)
        .setTitle("Player Positions")
        .setMessage(msg)
        .setPositiveButton("OK", nil)
        .show()
end

function exitGame()
    AlertDialog.Builder(activity)
        .setTitle("Exit Game")
        .setMessage("Do you really want to exit the game?")
        .setPositiveButton("Yes", function()
            if gameDialog then
                gameDialog.dismiss()
                gameDialog = nil
            end
            showMainMenuDialog()
        end)
        .setNegativeButton("No", nil)
        .show()
end

function confirmCloseApp()
    AlertDialog.Builder(activity)
        .setTitle("Exit")
        .setMessage("Do you want to exit the app?")
        .setPositiveButton("Yes", function()
            activity.finish()
        end)
        .setNegativeButton("No", nil)
        .show()
end

-- ===================== EDIT NAME =====================
function editName()
    local et = EditText(activity)
    et.setText(username)
    et.setSingleLine(true)
    et.setFilters({InputFilter.LengthFilter(20), InputFilter{filter=function(source, start, endPos, dest, dstart, dendPos)
        local str = tostring(source)
        for i=start, endPos-1 do
            local c = str:sub(i, i)
            if c == " " then
                return ""
            end
        end
        return nil
    end}})

    AlertDialog.Builder(activity)
        .setTitle("Edit Username")
        .setView(et)
        .setPositiveButton("Save", function()
            local newName = et.getText().toString()
            if newName:find(" ") then
                speak(_("username_error"))
                return
            end
            if newName == "" then
                speak("Username cannot be empty.")
                return
            end
            username = newName
            stats.playerName = username
            gameState.players[1] = username
            saveSettings()
            speak(_("username_changed", username))
            showMainMenuDialog()
        end)
        .setNegativeButton("Cancel", nil)
        .show()
end

-- ===================== LOGOUT =====================
function logout()
    AlertDialog.Builder(activity)
        .setTitle("Logout")
        .setMessage("Are you sure you want to logout? All your game data will be cleared.")
        .setPositiveButton("Yes", function()
            resetAllSettings()
            if menuDialog then
                menuDialog.dismiss()
                menuDialog = nil
            end
            if gameDialog then
                gameDialog.dismiss()
                gameDialog = nil
            end
            if settingsDialog then
                settingsDialog.dismiss()
                settingsDialog = nil
            end
            speak(_("logged_out"))
            if tts then
                pcall(function() tts.shutdown() end)
                tts = nil
            end
            initTts(nil)
            showRegistrationDialog()
        end)
        .setNegativeButton("No", nil)
        .show()
end

-- ===================== LANGUAGE PICKER =====================
function showLanguagePicker(title, callback)
    local allLanguages = languages
    local builder = AlertDialog.Builder(activity)
    local layout = LinearLayout(activity)
    layout.setOrientation(LinearLayout.VERTICAL)
    layout.setPadding(20,20,20,20)

    local searchBox = EditText(activity)
    searchBox.setHint("Search languages...")
    layout.addView(searchBox)

    local listView = ListView(activity)
    local adapter = ArrayAdapter(activity, android.R.layout.simple_list_item_1, {})
    listView.setAdapter(adapter)

    local function updateList(filter)
        local items = {}
        local f = tostring(filter) or ""
        for i, lang in ipairs(allLanguages) do
            local name = lang.name or ""
            if f == "" or string.find(string.lower(name), string.lower(f)) then
                table.insert(items, name .. " (" .. lang.code .. ")")
            end
        end
        adapter.clear()
        for i, item in ipairs(items) do
            adapter.add(item)
        end
        adapter.notifyDataSetChanged()
    end

    updateList("")

    searchBox.addTextChangedListener({
        onTextChanged = function(s, start, before, count)
            updateList(s)
        end
    })

    listView.setOnItemClickListener({onItemClick=function(parent, view, position, id)
        local selectedText = adapter.getItem(position)
        local code = nil
        for i, lang in ipairs(allLanguages) do
            if lang.name .. " (" .. lang.code .. ")" == selectedText then
                code = lang.code
                break
            end
        end
        if code then
            callback(code)
            if dlg then dlg.dismiss() end
        end
    end})

    layout.addView(listView)
    builder.setTitle(title)
    builder.setView(layout)
    builder.setPositiveButton("Cancel", nil)
    local dlg = builder.show()
end

-- ===================== LANGUAGE LIST =====================
languages = {
    {name="Afrikaans", code="af"},
    {name="Albanian", code="sq"},
    {name="Amharic", code="am"},
    {name="Arabic", code="ar"},
    {name="Armenian", code="hy"},
    {name="Assamese", code="as"},
    {name="Aymara", code="ay"},
    {name="Azerbaijani", code="az"},
    {name="Bambara", code="bm"},
    {name="Basque", code="eu"},
    {name="Belarusian", code="be"},
    {name="Bengali", code="bn"},
    {name="Bhojpuri", code="bho"},
    {name="Bosnian", code="bs"},
    {name="Bulgarian", code="bg"},
    {name="Catalan", code="ca"},
    {name="Cebuano", code="ceb"},
    {name="Chinese (Simplified)", code="zh-CN"},
    {name="Chinese (Traditional)", code="zh-TW"},
    {name="Corsican", code="co"},
    {name="Croatian", code="hr"},
    {name="Czech", code="cs"},
    {name="Danish", code="da"},
    {name="Dhivehi", code="dv"},
    {name="Dogri", code="doi"},
    {name="Dutch", code="nl"},
    {name="English", code="en"},
    {name="Esperanto", code="eo"},
    {name="Estonian", code="et"},
    {name="Ewe", code="ee"},
    {name="Filipino (Tagalog)", code="fil"},
    {name="Finnish", code="fi"},
    {name="French", code="fr"},
    {name="Frisian", code="fy"},
    {name="Galician", code="gl"},
    {name="Georgian", code="ka"},
    {name="German", code="de"},
    {name="Greek", code="el"},
    {name="Guarani", code="gn"},
    {name="Gujarati", code="gu"},
    {name="Haitian Creole", code="ht"},
    {name="Hausa", code="ha"},
    {name="Hawaiian", code="haw"},
    {name="Hebrew", code="he"},
    {name="Hindi", code="hi"},
    {name="Hmong", code="hmn"},
    {name="Hungarian", code="hu"},
    {name="Icelandic", code="is"},
    {name="Igbo", code="ig"},
    {name="Ilocano", code="ilo"},
    {name="Indonesian", code="id"},
    {name="Irish", code="ga"},
    {name="Italian", code="it"},
    {name="Japanese", code="ja"},
    {name="Javanese", code="jv"},
    {name="Kannada", code="kn"},
    {name="Kazakh", code="kk"},
    {name="Khmer", code="km"},
    {name="Kinyarwanda", code="rw"},
    {name="Konkani", code="gom"},
    {name="Korean", code="ko"},
    {name="Krio", code="kri"},
    {name="Kurdish", code="ku"},
    {name="Kurdish (Sorani)", code="ckb"},
    {name="Kyrgyz", code="ky"},
    {name="Lao", code="lo"},
    {name="Latin", code="la"},
    {name="Latvian", code="lv"},
    {name="Lingala", code="ln"},
    {name="Lithuanian", code="lt"},
    {name="Luganda", code="lg"},
    {name="Luxembourgish", code="lb"},
    {name="Macedonian", code="mk"},
    {name="Maithili", code="mai"},
    {name="Malagasy", code="mg"},
    {name="Malay", code="ms"},
    {name="Malayalam", code="ml"},
    {name="Maltese", code="mt"},
    {name="Maori", code="mi"},
    {name="Marathi", code="mr"},
    {name="Meiteilon (Manipuri)", code="mni-Mtei"},
    {name="Mongolian", code="mn"},
    {name="Myanmar (Burmese)", code="my"},
    {name="Nepali", code="ne"},
    {name="Norwegian", code="no"},
    {name="Nyanja (Chichewa)", code="ny"},
    {name="Odia (Oriya)", code="or"},
    {name="Oromo", code="om"},
    {name="Pashto", code="ps"},
    {name="Persian", code="fa"},
    {name="Polish", code="pl"},
    {name="Portuguese (Portugal, Brazil)", code="pt"},
    {name="Punjabi", code="pa"},
    {name="Quechua", code="qu"},
    {name="Romanian", code="ro"},
    {name="Russian", code="ru"},
    {name="Samoan", code="sm"},
    {name="Sanskrit", code="sa"},
    {name="Scots Gaelic", code="gd"},
    {name="Sepedi", code="nso"},
    {name="Serbian", code="sr"},
    {name="Sesotho", code="st"},
    {name="Shona", code="sn"},
    {name="Sindhi", code="sd"},
    {name="Sinhala (Sinhalese)", code="si"},
    {name="Slovak", code="sk"},
    {name="Slovenian", code="sl"},
    {name="Somali", code="so"},
    {name="Spanish", code="es"},
    {name="Sundanese", code="su"},
    {name="Swahili", code="sw"},
    {name="Swedish", code="sv"},
    {name="Tagalog (Filipino)", code="tl"},
    {name="Tajik", code="tg"},
    {name="Tamil", code="ta"},
    {name="Tatar", code="tt"},
    {name="Telugu", code="te"},
    {name="Thai", code="th"},
    {name="Tigrinya", code="ti"},
    {name="Tsonga", code="ts"},
    {name="Turkish", code="tr"},
    {name="Turkmen", code="tk"},
    {name="Twi (Akan)", code="ak"},
    {name="Ukrainian", code="uk"},
    {name="Urdu", code="ur"},
    {name="Uyghur", code="ug"},
    {name="Uzbek", code="uz"},
    {name="Vietnamese", code="vi"},
    {name="Welsh", code="cy"},
    {name="Xhosa", code="xh"},
    {name="Yiddish", code="yi"},
    {name="Yoruba", code="yo"},
    {name="Zulu", code="zu"}
}

-- ===================== GAME INFO =====================
function showGameInfo()
    local sections = {
        {
            title = "Introduction",
            content = "This is a voice‑guided Snake & Ladder game designed for blind users. You play against the computer. The goal is to reach the target number (50 or 100) exactly."
        },
        {
            title = "Gameplay",
            content = "On your turn, press 'Roll Dice' or swipe down. A random number from 1 to 6 will be spoken. Your token moves that many steps. If you land on the bottom of a ladder, you climb up. If you land on a snake's head, you slide down. You win if you land exactly on the target number. If you overshoot, you stay in place and your turn ends."
        },
        {
            title = "Controls",
            content = "• 'Roll Dice' button or swipe down – roll dice.\n• Swipe left – see current positions of all players.\n• Swipe right – exit game (back to menu).\n• Swipe up – close the app (with confirmation).\n• Double swipe left (only on menu) – edit your username.\n• Double swipe right (only on menu) – logout and reset all settings.\n• 'Profile' – view your stats and change your name.\n• 'Settings' – toggle sounds, adjust volumes, enable/disable voice, select TTS engine, and choose commentary language.\n• 'About' – connect with the developer and community.\n• 'How to Use' – this guide."
        },
        {
            title = "Settings Explained",
            content = "You can individually turn on/off and set volume for: Roll sound, Move steps, Ladder, Snake. The 'Enable Voice' switch turns Text‑to‑Speech on/off. You can select your preferred TTS engine and also set the commentary language (changes instantly)."
        },
        {
            title = "Game Modes",
            content = "You can choose from three modes: Pass and Play (2-4 players), Play with Computer (2 players), and Online (coming soon)."
        },
        {
            title = "Stats Tracking",
            content = "Your profile keeps track of wins, losses, snake bites, ladder climbs, and total games played. Your name can be edited there as well."
        }
    }

    local scroll = ScrollView(activity)
    local layout = LinearLayout(activity)
    layout.setOrientation(LinearLayout.VERTICAL)
    layout.setPadding(20,20,20,20)

    for i, sec in ipairs(sections) do
        local titleTv = TextView(activity)
        titleTv.setText(sec.title)
        titleTv.setTextSize(20)
        titleTv.setTypeface(nil, 1)
        titleTv.setPadding(0, 20, 0, 10)
        layout.addView(titleTv)

        local contentTv = TextView(activity)
        contentTv.setText(sec.content)
        contentTv.setTextSize(16)
        contentTv.setPadding(0, 0, 0, 20)
        layout.addView(contentTv)
    end

    scroll.addView(layout)

    AlertDialog.Builder(activity)
        .setTitle("Game Info")
        .setView(scroll)
        .setPositiveButton("Close", nil)
        .show()
end

-- ===================== GESTURE GUIDE =====================
function showGestureGuide()
    local layout = LinearLayout(activity)
    layout.setOrientation(LinearLayout.VERTICAL)
    layout.setPadding(20,20,20,20)

    local title = TextView(activity)
    title.setText("Gesture Guide")
    title.setTextSize(24)
    title.setGravity(Gravity.CENTER)
    layout.addView(title)

    local gestures = {
        "Swipe Down – Roll Dice (in game)",
        "Swipe Up – Close App (anywhere, confirmation)",
        "Swipe Right – Exit Game (go to menu)",
        "Swipe Left – Show player positions",
        "Double Swipe Left (menu only) – Edit username",
        "Double Swipe Right (menu only) – Logout & Reset Settings"
    }

    for i, g in ipairs(gestures) do
        local tv = TextView(activity)
        tv.setText(g)
        tv.setTextSize(18)
        tv.setPadding(0, 10, 0, 10)
        layout.addView(tv)
    end

    AlertDialog.Builder(activity)
        .setTitle("Gestures")
        .setView(layout)
        .setPositiveButton("Close", nil)
        .show()
end

-- ===================== HOW TO USE (चयन डायलॉग) =====================
function showHowToUse()
    AlertDialog.Builder(activity)
        .setTitle("What do you want to know?")
        .setItems({"Game Info", "Gesture Guide"}, function(dialog, which)
            if which == 0 then
                showGameInfo()
            else
                showGestureGuide()
            end
        end)
        .setNegativeButton("Cancel", nil)
        .show()
end

-- ===================== ABOUT (MORE OPTIONS में) =====================
function showAbout()
    local layout = LinearLayout(activity)
    layout.setOrientation(LinearLayout.VERTICAL)
    layout.setPadding(20,20,20,20)

    local title = TextView(activity)
    title.setText("About Snake & Ladder")
    title.setTextSize(24)
    title.setGravity(Gravity.CENTER)
    layout.addView(title)

    local desc = TextView(activity)
    desc.setText("A voice-guided board game for everyone, specially designed for blind users. Roll the dice, climb ladders, avoid snakes, and reach " .. winTarget .. " to win!")
    desc.setTextSize(16)
    desc.setPadding(10,10,10,10)
    layout.addView(desc)

    local conn = TextView(activity)
    conn.setText("Connect with us:")
    conn.setTextSize(18)
    conn.setPadding(10,10,10,10)
    layout.addView(conn)

    local function addLinkBtn(text, url)
        local btn = Button(activity)
        btn.setText(text)
        btn.setOnClickListener({onClick=function() openLink(url) end})
        layout.addView(btn)
    end

    addLinkBtn("Telegram: SP Tech", "https://t.me/spry1_3valenzuela")
    addLinkBtn("WhatsApp Community", "https://chat.whatsapp.com/Kb3QOapabwZGOgzzO8FZof")
    addLinkBtn("Blind Tech Hub (Telegram)", "https://t.me/blindtechhubq7c")
    addLinkBtn("Audio Tutorials", "https://t.me/+1Aazfn0FJ9oxZWE1")
    addLinkBtn("SP Tech Hub", "https://t.me/S_P_Tech_Hub")
    addLinkBtn("WhatsApp Channel", "https://whatsapp.com/channel/0029VbAVDj23AzNYccK2KR3T")
    addLinkBtn("YouTube Channel", "https://youtube.com/@blindtechhub-p2s?si=9I8g9mvMzgc9S9ez")

    AlertDialog.Builder(activity)
        .setView(layout)
        .setPositiveButton("Close", nil)
        .show()
end

function openLink(url)
    local intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
    activity.startActivity(intent)
end

-- ===================== PRIVACY POLICY (सेक्शन में) =====================
function getPrivacyPolicySections()
    return {
        {
            title = "Snake & Ladder – Privacy Policy",
            content = "Last updated: August 2026\n\nThis privacy policy applies to the Snake & Ladder game application (hereinafter referred to as 'the App') developed by Mezab Ali."
        },
        {
            title = "1. Information Collection and Use",
            content = "The App does not collect, store, or transmit any personal information. All data (such as your username, game statistics, and sound settings) are stored locally on your device using Android's SharedPreferences. No data is sent to any server or third party."
        },
        {
            title = "2. Permissions",
            content = "The App requires the following permissions:\n- INTERNET: Used only to display links to external resources (Telegram, WhatsApp, YouTube, etc.) within the About section.\n- TTS (Text-to-Speech): Used for voice announcements. No voice data is recorded or stored."
        },
        {
            title = "3. Third-Party Services",
            content = "The App does not integrate with any third-party analytics, advertising, or tracking services."
        },
        {
            title = "4. Data Security",
            content = "Since all data is stored locally on your device, it is protected by your device's own security measures. We do not have access to your data."
        },
        {
            title = "5. Children's Privacy",
            content = "The App is suitable for all ages and does not knowingly collect any personal information from children under 13."
        },
        {
            title = "6. Changes to This Policy",
            content = "We may update this privacy policy from time to time. Any changes will be reflected in the App."
        },
        {
            title = "7. Contact",
            content = "If you have any questions about this privacy policy, you can contact the developer via the links provided in the About section."
        },
        {
            title = "",
            content = "© 2026 Mezab Ali Creations"
        }
    }
end

-- ===================== CREATE PRIVACY POLICY VIEW (WITH CARDS) =====================
function createPrivacyPolicyView(showAccept)
    local outerLayout = LinearLayout(activity)
    outerLayout.setOrientation(LinearLayout.VERTICAL)
    outerLayout.setPadding(20,20,20,20)

    local scroll = ScrollView(activity)
    local container = LinearLayout(activity)
    container.setOrientation(LinearLayout.VERTICAL)
    container.setPadding(0,0,0,0)

    local sections = getPrivacyPolicySections()
    for i, sec in ipairs(sections) do
        local card = LinearLayout(activity)
        card.setOrientation(LinearLayout.VERTICAL)
        card.setPadding(15,15,15,15)
        local gd = GradientDrawable()
        gd.setColor(0xFFFFFFFF)
        gd.setStroke(2, 0xFFCCCCCC)
        card.setBackgroundDrawable(gd)
        local params = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
        params.setMargins(0,0,0,15)
        card.setLayoutParams(params)

        if sec.title ~= "" then
            local titleTv = TextView(activity)
            titleTv.setText(sec.title)
            titleTv.setTextSize(18)
            titleTv.setTypeface(nil, 1)
            titleTv.setPadding(0,0,0,5)
            card.addView(titleTv)
        end

        local contentTv = TextView(activity)
        contentTv.setText(sec.content)
        contentTv.setTextSize(16)
        contentTv.setPadding(0,0,0,0)
        card.addView(contentTv)

        container.addView(card)
    end

    scroll.addView(container)

    local scrollParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1)
    scroll.setLayoutParams(scrollParams)
    outerLayout.addView(scroll)

    if showAccept then
        local acceptCheck = CheckBox(activity)
        acceptCheck.setText("I accept the Privacy Policy")
        acceptCheck.setChecked(false)
        acceptCheck.setPadding(0,20,0,10)
        outerLayout.addView(acceptCheck)

        local okBtn = Button(activity)
        okBtn.setText("OK")
        okBtn.setOnClickListener({onClick=function()
            if acceptCheck.isChecked() then
                privacyAccepted = true
                saveSettings()
                if welcomeDialog then
                    welcomeDialog.dismiss()
                    welcomeDialog = nil
                end
                showRegistrationDialog()
            else
                speak("Please accept the privacy policy to continue.")
            end
        end})
        outerLayout.addView(okBtn)

        return outerLayout
    else
        return outerLayout
    end
end

-- ===================== SHOW PRIVACY POLICY (MORE OPTIONS) =====================
function showPrivacyPolicy()
    local view = createPrivacyPolicyView(false)
    AlertDialog.Builder(activity)
        .setTitle("Privacy Policy")
        .setView(view)
        .setPositiveButton("Close", nil)
        .show()
end

-- ===================== WELCOME SCREEN (Privacy Policy Acceptance) =====================
welcomeDialog = nil

function showWelcomeDialog()
    local view = createPrivacyPolicyView(true)
    local builder = AlertDialog.Builder(activity)
    builder.setTitle("Welcome")
    builder.setView(view)
    builder.setCancelable(false)
    welcomeDialog = builder.show()
end

-- ===================== REGISTRATION DIALOG =====================
function showRegistrationDialog()
    local layout = LinearLayout(activity)
    layout.setOrientation(LinearLayout.VERTICAL)
    layout.setPadding(20,20,20,20)
    layout.setMinimumWidth(500)

    local title = TextView(activity)
    title.setText("Registration")
    title.setTextSize(24)
    title.setGravity(Gravity.CENTER)
    layout.addView(title)

    local desc = TextView(activity)
    desc.setText(_("enter_username"))
    desc.setTextSize(16)
    desc.setPadding(0,10,0,10)
    layout.addView(desc)

    local editText = EditText(activity)
    editText.setHint("Username")
    editText.setSingleLine(true)
    editText.setFilters({InputFilter.LengthFilter(20), InputFilter{filter=function(source, start, endPos, dest, dstart, dendPos)
        local str = tostring(source)
        for i=start, endPos-1 do
            local c = str:sub(i, i)
            if c == " " then
                return ""
            end
        end
        return nil
    end}})
    layout.addView(editText)

    local okBtn = Button(activity)
    okBtn.setText("OK")
    okBtn.setOnClickListener({onClick=function()
        local name = editText.getText().toString()
        if name:find(" ") then
            speak(_("username_error"))
            return
        end
        if name == "" then
            speak("Username cannot be empty.")
            return
        end
        registered = true
        username = name
        stats.playerName = username
        gameState.players = {username}
        gameState.positions = {0}
        saveSettings()
        if regDialog then
            regDialog.dismiss()
            regDialog = nil
        end
        speak(_("registration_success", username))
        showMainMenuDialog()
    end})
    layout.addView(okBtn)

    local builder = AlertDialog.Builder(activity)
    builder.setTitle("Snake & Ladder")
    builder.setView(layout)
    builder.setCancelable(false)
    regDialog = builder.show()
end

regDialog = nil

-- ===================== MODE SELECTION =====================
function showModeSelection()
    AlertDialog.Builder(activity)
        .setTitle(_("select_mode"))
        .setItems({_("pass_play"), _("play_computer"), _("play_online")}, function(dialog, which)
            if which == 0 then
                -- Pass and Play
                showPlayerSetup()
            elseif which == 1 then
                -- Play with Computer
                gameState.gameMode = "computer"
                gameState.players = {username, _("computer")}
                gameState.positions = {0, 0}
                gameState.currentPlayer = 1
                gameState.isComputerTurn = false
                gameState.isGameOver = false
                startNewGame()
            elseif which == 2 then
                -- Online Players - Coming Soon Dialog
                AlertDialog.Builder(activity)
                    .setTitle("Online Mode")
                    .setMessage(_("coming_soon"))
                    .setPositiveButton("OK", function()
                        -- Go back to home (main menu)
                        if menuDialog then
                            menuDialog.dismiss()
                            menuDialog = nil
                        end
                        showMainMenuDialog()
                    end)
                    .setCancelable(false)
                    .show()
            end
        end)
        .setNegativeButton("Cancel", nil)
        .show()
end

-- ===================== PLAYER SETUP (Pass and Play) =====================
function showPlayerSetup()
    local layout = LinearLayout(activity)
    layout.setOrientation(LinearLayout.VERTICAL)
    layout.setPadding(20,20,20,20)
    layout.setMinimumWidth(500)

    local title = TextView(activity)
    title.setText(_("player_setup"))
    title.setTextSize(24)
    title.setGravity(Gravity.CENTER)
    layout.addView(title)

    -- Player 1 is fixed
    local p1 = TextView(activity)
    p1.setText("Player 1: " .. username .. " (You)")
    p1.setTextSize(16)
    p1.setPadding(0,10,0,5)
    layout.addView(p1)

    local et2 = EditText(activity)
    et2.setHint(_("player2_name"))
    et2.setSingleLine(true)
    layout.addView(et2)

    local et3 = EditText(activity)
    et3.setHint(_("player3_name"))
    et3.setSingleLine(true)
    layout.addView(et3)

    local et4 = EditText(activity)
    et4.setHint(_("player4_name"))
    et4.setSingleLine(true)
    layout.addView(et4)

    local startBtn = Button(activity)
    startBtn.setText(_("start_passing"))
    startBtn.setOnClickListener({onClick=function()
        local p2 = et2.getText().toString()
        if p2 == "" or p2:find("^%s*$") then
            speak(_("please_enter_p2"))
            return
        end
        local players = {username, p2}
        local p3 = et3.getText().toString()
        if p3 ~= "" and not p3:find("^%s*$") then
            table.insert(players, p3)
        end
        local p4 = et4.getText().toString()
        if p4 ~= "" and not p4:find("^%s*$") then
            table.insert(players, p4)
        end
        gameState.gameMode = "pass"
        gameState.players = players
        gameState.positions = {}
        for i=1, #players do gameState.positions[i] = 0 end
        gameState.currentPlayer = 1
        gameState.isComputerTurn = false
        gameState.isGameOver = false
        if playerSetupDialog then playerSetupDialog.dismiss() end
        startNewGame()
    end})
    layout.addView(startBtn)

    local builder = AlertDialog.Builder(activity)
    builder.setTitle("Pass and Play")
    builder.setView(layout)
    builder.setCancelable(false)
    playerSetupDialog = builder.show()
end

playerSetupDialog = nil

-- ===================== START NEW GAME (TARGET SELECTION) =====================
function startNewGame()
    AlertDialog.Builder(activity)
        .setTitle("Select Game Mode")
        .setMessage("Choose the winning target:")
        .setPositiveButton("50", function()
            winTarget = 50
            actuallyStartGame()
        end)
        .setNegativeButton("100", function()
            winTarget = 100
            actuallyStartGame()
        end)
        .setCancelable(false)
        .show()
end

function actuallyStartGame()
    for i=1, #gameState.players do
        gameState.positions[i] = 0
    end
    gameState.currentPlayer = 1
    gameState.isGameOver = false
    if gameState.gameMode == "computer" then
        gameState.isComputerTurn = false
    else
        gameState.isComputerTurn = false
    end
    showGameDialog()
end

-- ===================== GAME DIALOG =====================
function showGameDialog()
    if gameDialog then
        gameDialog.dismiss()
        gameDialog = nil
    end

    if menuDialog then
        menuDialog.dismiss()
        menuDialog = nil
    end

    local layout = LinearLayout(activity)
    layout.setOrientation(LinearLayout.VERTICAL)
    layout.setPadding(20,20,20,20)
    layout.setMinimumWidth(600)

    target_label = TextView(activity)
    target_label.setText("Target: " .. winTarget)
    target_label.setTextSize(16)
    target_label.setTextColor(0xFF0000FF)
    target_label.setGravity(Gravity.CENTER)
    layout.addView(target_label)

    status_texts = {}
    for i, name in ipairs(gameState.players) do
        local tv = TextView(activity)
        tv.setId(i)
        tv.setText(name .. ": Position 0")
        tv.setTextSize(20)
        layout.addView(tv)
        status_texts[i] = tv
    end

    status_tv = TextView(activity)
    status_tv.setText(_("turn_message", gameState.players[gameState.currentPlayer] or ""))
    status_tv.setTextSize(18)
    status_tv.setTextColor(0xFFFF0000)
    status_tv.setGravity(Gravity.CENTER)
    layout.addView(status_tv)

    roll_btn = Button(activity)
    roll_btn.setText("Roll Dice")
    roll_btn.setOnClickListener({onClick=function()
        roll_btn.setEnabled(false)
        if gameState.players[gameState.currentPlayer] == _("computer") then
            return
        end
        executeTurn(gameState.currentPlayer)
    end})
    layout.addView(roll_btn)

    local builder = AlertDialog.Builder(activity)
    builder.setTitle("Snake & Ladder - Game")
    builder.setView(layout)
    builder.setCancelable(false)
    gameDialog = builder.show()

    gameDialog.setOnKeyListener({onKey=function(dialog, keyCode, event)
        if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
            confirmCloseApp()
            return true
        end
        return false
    end})

    local window = gameDialog.getWindow()
    if window then
        local decorView = window.getDecorView()
        setupGestureListener(decorView, true)
    end

    gameDialog.setOnDismissListener({onDismiss=function()
        gameDialog = nil
        if not gameState.isGameOver then
            showMainMenuDialog()
        end
    end})

    updateUI()
    if gameState.players[gameState.currentPlayer] == _("computer") then
        roll_btn.setEnabled(false)
        task(1500, function()
            if not gameState.isGameOver then
                executeComputerTurn()
            end
        end)
    else
        roll_btn.setEnabled(true)
    end
    status_tv.setText(_("turn_message", gameState.players[gameState.currentPlayer]))
end

-- ===================== TURN LOGIC =====================
function executeTurn(playerIndex)
    local playerName = gameState.players[playerIndex]
    local dice = math.random(1, 6)

    playSound(sRoll, "roll")
    speak(playerName .. " " .. _("rolled") .. " " .. dice)

    local newPos = gameState.positions[playerIndex] + dice

    if newPos > winTarget then
        speak(playerName .. " " .. _("overshot") .. " " .. gameState.positions[playerIndex])
        updateUI()
        nextTurn()
        return
    end

    task(1000, function()
        playStepSounds(dice)
        task(dice*350, function()
            local finalPos = newPos
            if ladders[newPos] then
                playSound(sLadder, "ladder")
                finalPos = ladders[newPos]
                stats.ladderClimbs = stats.ladderClimbs + 1
                speak(playerName .. " " .. _("climbed_ladder") .. " " .. finalPos)
            elseif snakes[newPos] then
                playSound(sSnake, "snake")
                finalPos = snakes[newPos]
                stats.snakeBites = stats.snakeBites + 1
                speak(playerName .. " " .. _("bitten_snake") .. " " .. finalPos)
            else
                speak(playerName .. " " .. _("moved_to") .. " " .. finalPos)
            end

            gameState.positions[playerIndex] = finalPos
            updateUI()

            if finalPos >= winTarget then
                gameState.isGameOver = true
                stats.totalGames = stats.totalGames + 1
                if playerName == _("computer") then
                    stats.losses = stats.losses + 1
                else
                    stats.wins = stats.wins + 1
                end
                speak(playerName .. " " .. _("wins_game"))
                local resultMsg = (playerName == _("computer") and _("you_lose") or _("you_win"))
                task(500, function()
                    showResultDialog(resultMsg .. "\n" .. playerName .. " " .. _("wins_game"))
                end)
                if gameDialog then
                    gameDialog.dismiss()
                    gameDialog = nil
                end
                task(300, function()
                    showMainMenuDialog()
                end)
                return
            end

            if dice == 6 then
                speak(_("extra_turn"))
                task(500, function()
                    if gameState.players[playerIndex] == _("computer") and gameState.gameMode == "computer" then
                        executeComputerTurn()
                    else
                        roll_btn.setEnabled(true)
                        status_tv.setText(_("turn_message", playerName))
                    end
                end)
                return
            else
                nextTurn()
            end
        end)
    end)
end

function nextTurn()
    if gameState.isGameOver then return end
    local totalPlayers = #gameState.players
    if totalPlayers == 0 then return end
    local next = gameState.currentPlayer + 1
    if next > totalPlayers then next = 1 end
    gameState.currentPlayer = next
    status_tv.setText(_("turn_message", gameState.players[next]))
    updateUI()

    if gameState.players[next] == _("computer") then
        roll_btn.setEnabled(false)
        task(1000, function()
            if not gameState.isGameOver then
                executeComputerTurn()
            end
        end)
    else
        roll_btn.setEnabled(true)
    end
end

function executeComputerTurn()
    local playerIndex = nil
    for i, name in ipairs(gameState.players) do
        if name == _("computer") then
            playerIndex = i
            break
        end
    end
    if not playerIndex then return end
    if gameState.isGameOver then return end
    executeTurn(playerIndex)
end

-- ===================== UI UPDATE =====================
function updateUI()
    for i, name in ipairs(gameState.players) do
        local tv = status_texts[i]
        if tv then
            tv.setText(name .. ": Position " .. (gameState.positions[i] or 0))
        end
    end
end

-- ===================== RESULT DIALOG =====================
function showResultDialog(msg)
    AlertDialog.Builder(activity)
        .setTitle("Game Over")
        .setMessage(msg)
        .setPositiveButton("Close", nil)
        .setCancelable(false)
        .show()
end

-- ===================== MAIN MENU =====================
gameDialog = nil
menuDialog = nil

function showMainMenuDialog()
    if menuDialog then
        menuDialog.dismiss()
        menuDialog = nil
    end
    if gameDialog then
        gameDialog.dismiss()
        gameDialog = nil
    end

    local layout = LinearLayout(activity)
    layout.setOrientation(LinearLayout.VERTICAL)
    layout.setPadding(20,20,20,20)
    layout.setMinimumWidth(500)

    local devInfo = TextView(activity)
    devInfo.setText("Developed by Mezab Ali | Blind Tech Hub Team")
    devInfo.setTextSize(14)
    devInfo.setGravity(Gravity.CENTER)
    devInfo.setPadding(0,0,0,10)
    layout.addView(devInfo)

    local greeting = getTimeGreeting()
    local welcomeMsg = "Welcome, " .. username .. "! " .. greeting
    local welcomeTv = TextView(activity)
    welcomeTv.setText(welcomeMsg)
    welcomeTv.setTextSize(18)
    welcomeTv.setGravity(Gravity.CENTER)
    welcomeTv.setPadding(0,0,0,15)
    layout.addView(welcomeTv)

    local btnProfile = Button(activity)
    btnProfile.setText("PROFILE")
    btnProfile.setPadding(20,10,20,10)
    btnProfile.setOnClickListener({onClick=function() showProfile() end})
    layout.addView(btnProfile)

    local btnMoreOptions = Button(activity)
    btnMoreOptions.setText("MORE OPTIONS")
    btnMoreOptions.setPadding(20,10,20,10)
    btnMoreOptions.setOnClickListener({onClick=function(v)
        local p = PopupMenu(activity, v)
        p.getMenu().add("About")
        p.getMenu().add("Privacy Policy")
        p.setOnMenuItemClickListener({onMenuItemClick=function(item)
            local title = item.getTitle()
            if title == "About" then
                showAbout()
            elseif title == "Privacy Policy" then
                showPrivacyPolicy()
            end
            return true
        end})
        p.show()
    end})
    layout.addView(btnMoreOptions)

    local btnStart = Button(activity)
    btnStart.setText("START GAME")
    btnStart.setPadding(20,10,20,10)
    btnStart.setTextSize(18)
    btnStart.setOnClickListener({onClick=function()
        if menuDialog then
            menuDialog.dismiss()
            menuDialog = nil
        end
        showModeSelection()
    end})
    layout.addView(btnStart)

    local btnSettings = Button(activity)
    btnSettings.setText("SETTINGS")
    btnSettings.setPadding(20,10,20,10)
    btnSettings.setOnClickListener({onClick=function() showSettings() end})
    layout.addView(btnSettings)

    local btnHowTo = Button(activity)
    btnHowTo.setText("HOW TO USE")
    btnHowTo.setPadding(20,10,20,10)
    btnHowTo.setOnClickListener({onClick=function() showHowToUse() end})
    layout.addView(btnHowTo)

    local btnExit = Button(activity)
    btnExit.setText("EXIT")
    btnExit.setPadding(20,10,20,10)
    btnExit.setTextSize(16)
    btnExit.setOnClickListener({onClick=function()
        confirmCloseApp()
    end})
    layout.addView(btnExit)

    local copyright = TextView(activity)
    copyright.setText("© 2026 Mezab Ali Creations")
    copyright.setTextSize(12)
    copyright.setGravity(Gravity.CENTER)
    copyright.setPadding(0,15,0,0)
    layout.addView(copyright)

    local builder = AlertDialog.Builder(activity)
    builder.setTitle("Snake & Ladder")
    builder.setView(layout)
    builder.setCancelable(false)
    menuDialog = builder.show()

    menuDialog.setOnKeyListener({onKey=function(dialog, keyCode, event)
        if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
            confirmCloseApp()
            return true
        end
        return false
    end})

    local window = menuDialog.getWindow()
    if window then
        local decorView = window.getDecorView()
        setupGestureListener(decorView, false)
    end
end

-- ===================== SETTINGS (with Logout button) =====================
settingsDialog = nil

function showSettings()
    local scroll = ScrollView(activity)
    local layout = LinearLayout(activity)
    layout.setOrientation(LinearLayout.VERTICAL)
    layout.setPadding(20,20,20,20)

    local effectTitle = TextView(activity)
    effectTitle.setText("Sound Effects")
    effectTitle.setTextSize(20)
    effectTitle.setTypeface(nil, 1)
    layout.addView(effectTitle)

    local function addEffectRow(label, checkedVar, volVar)
        local row = LinearLayout(activity)
        row.setOrientation(LinearLayout.HORIZONTAL)
        row.setGravity(Gravity.CENTER_VERTICAL)

        local chk = CheckBox(activity)
        chk.setText(label)
        chk.setChecked(checkedVar)
        row.addView(chk)

        local seek = SeekBar(activity)
        seek.setMax(100)
        seek.setProgress(volVar)
        seek.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT, 1))
        row.addView(seek)

        layout.addView(row)
        return chk, seek
    end

    local chkRoll, seekRoll = addEffectRow("Roll", soundRoll, rollVol)
    local chkMove, seekMove = addEffectRow("Move", soundMove, moveVol)
    local chkLadder, seekLadder = addEffectRow("Ladder", soundLadder, ladderVol)
    local chkSnake, seekSnake = addEffectRow("Snake", soundSnake, snakeVol)

    local voiceTitle = TextView(activity)
    voiceTitle.setText("Voice")
    voiceTitle.setTextSize(20)
    voiceTitle.setTypeface(nil, 1)
    voiceTitle.setPadding(0, 20, 0, 0)
    layout.addView(voiceTitle)

    local chkTts = CheckBox(activity)
    chkTts.setText("Enable Voice (TTS)")
    chkTts.setChecked(ttsEnabled)
    layout.addView(chkTts)

    local engineLabel = TextView(activity)
    engineLabel.setText("TTS Engine:")
    engineLabel.setTextSize(16)
    engineLabel.setPadding(0,10,0,0)
    layout.addView(engineLabel)

    local engineStatus = TextView(activity)
    local currentEngineName = "Default"
    if selectedTtsEngine then
        local pm = activity.getPackageManager()
        local intent = Intent(TextToSpeech.Engine.INTENT_ACTION_TTS_SERVICE)
        local list = pm.queryIntentServices(intent, 0)
        for i=0, list.size()-1 do
            local info = list.get(i)
            if info.serviceInfo.packageName == selectedTtsEngine then
                local label = info.loadLabel(pm)
                if label then currentEngineName = tostring(label) else currentEngineName = selectedTtsEngine end
                break
            end
        end
    end
    engineStatus.setText("Current: " .. currentEngineName)
    engineStatus.setTextSize(14)
    engineStatus.setTextColor(0xFF666666)
    engineStatus.setPadding(0,5,0,10)
    layout.addView(engineStatus)

    local selectEngineBtn = Button(activity)
    selectEngineBtn.setText("Select TTS Engine")
    selectEngineBtn.setOnClickListener({onClick=function()
        local pm = activity.getPackageManager()
        local intent = Intent(TextToSpeech.Engine.INTENT_ACTION_TTS_SERVICE)
        local list = pm.queryIntentServices(intent, 0)
        local names = {}
        local packages = {}
        for i=0, list.size()-1 do
            local info = list.get(i)
            local label = info.loadLabel(pm)
            local name = label and tostring(label) or info.serviceInfo.packageName
            table.insert(names, name .. " (" .. info.serviceInfo.packageName .. ")")
            table.insert(packages, info.serviceInfo.packageName)
        end
        if #names == 0 then
            AlertDialog.Builder(activity).setMessage("No TTS engines found.").setPositiveButton("OK", nil).show()
            return
        end
        AlertDialog.Builder(activity)
            .setTitle("Choose TTS Engine")
            .setItems(names, function(dialog, which)
                local pkg = packages[which+1]
                selectedTtsEngine = pkg
                initTts(pkg)
                engineStatus.setText("Current: " .. names[which+1])
                task(500, function()
                    speak(_("tts_engine_changed"))
                end)
                saveSettings()
            end)
            .show()
    end})
    layout.addView(selectEngineBtn)

    local commLangLabel = TextView(activity)
    commLangLabel.setText("Commentary Language:")
    commLangLabel.setTextSize(16)
    commLangLabel.setPadding(0,10,0,0)
    layout.addView(commLangLabel)

    local commLangStatus = TextView(activity)
    local currentCommLangName = "English"
    for i, lang in ipairs(languages) do
        if lang.code == commentaryLangCode then
            currentCommLangName = lang.name
            break
        end
    end
    commLangStatus.setText("Current: " .. currentCommLangName)
    commLangStatus.setTextSize(14)
    commLangStatus.setTextColor(0xFF666666)
    commLangStatus.setPadding(0,5,0,10)
    layout.addView(commLangStatus)

    local commLangBtn = Button(activity)
    commLangBtn.setText("Select Commentary Language")
    commLangBtn.setOnClickListener({onClick=function()
        showLanguagePicker("Select Commentary Language", function(code)
            commentaryLangCode = code
            local name = "Unknown"
            for i, lang in ipairs(languages) do
                if lang.code == code then
                    name = lang.name
                    break
                end
            end
            commLangStatus.setText("Current: " .. name)
            if tts then
                local loc = Locale.forLanguageTag(code)
                if loc == nil or loc.getLanguage() == "" then
                    loc = Locale.US
                end
                local result = tts.setLanguage(loc)
                if result == TextToSpeech.LANG_MISSING_DATA or result == TextToSpeech.LANG_NOT_SUPPORTED then
                    tts.setLanguage(Locale.getDefault())
                end
                task(300, function()
                    speak(_("commentary_changed", name))
                end)
            end
            saveSettings()
        end)
    end})
    layout.addView(commLangBtn)

    local saveBtn = Button(activity)
    saveBtn.setText("Save Settings")
    saveBtn.setOnClickListener({onClick=function()
        soundRoll = chkRoll.isChecked()
        soundMove = chkMove.isChecked()
        soundLadder = chkLadder.isChecked()
        soundSnake = chkSnake.isChecked()
        rollVol = seekRoll.getProgress()
        moveVol = seekMove.getProgress()
        ladderVol = seekLadder.getProgress()
        snakeVol = seekSnake.getProgress()
        ttsEnabled = chkTts.isChecked()

        if not ttsEnabled then
            if tts then
                pcall(function() tts.shutdown() end)
                tts = nil
            end
        else
            if tts == nil then
                initTts(selectedTtsEngine)
            end
        end

        saveSettings()
        speak(_("settings_saved"))
        if settingsDialog then
            settingsDialog.dismiss()
            settingsDialog = nil
        end
    end})
    layout.addView(saveBtn)

    local logoutBtn = Button(activity)
    logoutBtn.setText("Logout")
    logoutBtn.setPadding(20,10,20,10)
    logoutBtn.setTextColor(0xFFFF0000)
    logoutBtn.setOnClickListener({onClick=function()
        logout()
    end})
    layout.addView(logoutBtn)

    scroll.addView(layout)

    local builder = AlertDialog.Builder(activity)
    builder.setTitle("Settings")
    builder.setView(scroll)
    builder.setPositiveButton("Close", function()
        if settingsDialog then
            settingsDialog.dismiss()
            settingsDialog = nil
        end
    end)
    settingsDialog = builder.show()
end

-- ===================== PROFILE =====================
function showProfile()
    local layout = LinearLayout(activity)
    layout.setOrientation(LinearLayout.VERTICAL)
    layout.setPadding(20,20,20,20)

    local title = TextView(activity)
    title.setText("Profile")
    title.setTextSize(24)
    title.setGravity(Gravity.CENTER)
    layout.addView(title)

    local nameTv = TextView(activity)
    nameTv.setText("Name: " .. stats.playerName)
    nameTv.setTextSize(18)
    layout.addView(nameTv)

    local winsTv = TextView(activity)
    winsTv.setText("Wins: " .. stats.wins)
    winsTv.setTextSize(16)
    layout.addView(winsTv)

    local lossesTv = TextView(activity)
    lossesTv.setText("Losses: " .. stats.losses)
    lossesTv.setTextSize(16)
    layout.addView(lossesTv)

    local snakeTv = TextView(activity)
    snakeTv.setText("Snake Bites: " .. stats.snakeBites)
    snakeTv.setTextSize(16)
    layout.addView(snakeTv)

    local ladderTv = TextView(activity)
    ladderTv.setText("Ladder Climbs: " .. stats.ladderClimbs)
    ladderTv.setTextSize(16)
    layout.addView(ladderTv)

    local totalTv = TextView(activity)
    totalTv.setText("Total Games: " .. stats.totalGames)
    totalTv.setTextSize(16)
    layout.addView(totalTv)

    local editBtn = Button(activity)
    editBtn.setText("Edit Name")
    editBtn.setOnClickListener({onClick=function()
        local et = EditText(activity)
        et.setText(stats.playerName)
        AlertDialog.Builder(activity)
            .setTitle("Change Name")
            .setView(et)
            .setPositiveButton("Save", function()
                stats.playerName = et.getText().toString()
                username = stats.playerName
                gameState.players[1] = username
                nameTv.setText("Name: " .. stats.playerName)
                saveSettings()
                updateUI()
                showMainMenuDialog()
            end)
            .setNegativeButton("Cancel", nil)
            .show()
    end})
    layout.addView(editBtn)

    local shareBtn = Button(activity)
    shareBtn.setText("Share Profile")
    shareBtn.setOnClickListener({onClick=function()
        local shareText = "My Snake & Ladder Profile:\n" ..
                          "Name: " .. stats.playerName .. "\n" ..
                          "Wins: " .. stats.wins .. "\n" ..
                          "Losses: " .. stats.losses .. "\n" ..
                          "Snake Bites: " .. stats.snakeBites .. "\n" ..
                          "Ladder Climbs: " .. stats.ladderClimbs .. "\n" ..
                          "Total Games: " .. stats.totalGames
        local intent = Intent(Intent.ACTION_SEND)
        intent.setType("text/plain")
        intent.putExtra(Intent.EXTRA_TEXT, shareText)
        activity.startActivity(Intent.createChooser(intent, "Share Profile"))
    end})
    layout.addView(shareBtn)

    AlertDialog.Builder(activity)
        .setView(layout)
        .setPositiveButton("Close", nil)
        .show()
end

-- ===================== STARTUP =====================
if not privacyAccepted then
    showWelcomeDialog()
elseif not registered then
    showRegistrationDialog()
else
    task(300, function()
        speak(_("welcome_back", username))
    end)
    showMainMenuDialog()
end