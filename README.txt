==================================================================
  PORTABLE QWEN  -  an offline AI chat that runs from this USB drive
==================================================================

Works on:  Windows 10/11 (x64 and ARM), macOS (Apple Silicon and Intel),
           Linux (x64 and ARM64, Ubuntu 22.04 / Debian 12 / Fedora 35 or newer).
No install, no internet, no admin rights needed. Nothing leaves your computer.

------------------------------------------------------------------
 HOW TO START
------------------------------------------------------------------

 WINDOWS
   Double-click  START-WINDOWS.bat
   (If Windows shows "Windows protected your PC", click
    "More info" -> "Run anyway".)

 macOS
   Double-click  START-MAC.command
   If that doesn't work: open Terminal, type  bash  and a space,
   drag START-MAC.command into the Terminal window, press Enter.

 LINUX
   Open a terminal and run:
       bash /path/to/the/USB/START-LINUX.sh
   (e.g.  bash /media/$USER/AI-small/AI-Small/START-LINUX.sh )

 A black/terminal window opens and loads the model (1-4 minutes
 from USB, depending on the drive's speed). Your web browser then opens the chat page automatically:
       http://127.0.0.1:8080
 Keep the terminal window open while chatting. Close it to stop the AI.

 "SERVER UNAVAILABLE" IN THE BROWSER?
   The chat page is only the screen - the AI runs in the terminal
   window. That message means the window was closed or the AI is
   still loading. Fix: double-click START-WINDOWS.bat (or the Mac/Linux
   file) again, wait until it says "listening", then click Retry.
   Starting it twice is safe - it just reopens the chat. If the AI
   crashes it restarts itself automatically (up to 3 times).
   Your old chats are saved in your browser (not on the USB), so they
   only appear on the same computer + browser.

 Options (add after the command, e.g.  START-WINDOWS.bat chat ):
   chat   chat inside the terminal window instead of the browser
   cpu    don't use the graphics card (use this if it crashes)
   fast   turn off "thinking" - much quicker answers, but less smart
          and worse at maths (not recommended for money questions)

------------------------------------------------------------------
 INVESTMENT RESEARCH ASSISTANT (Stake property, Indian stocks, forex)
------------------------------------------------------------------

 The AI starts as your Investment Research Assistant. Its rules are in
       prompts/system-prompt.txt
 Edit that file (Notepad / TextEdit) to change its role. Delete or
 rename it to get a normal general-purpose assistant.
 (In the web chat the rules are pre-filled under Settings -> System
 Message for every NEW chat. If you changed that setting yourself in
 your browser before, your own setting wins.)

 What it does:
 * Stake property: yield, your monthly/yearly income, value after
   1/3/5 years, total return, risks, and BUY / WAIT / AVOID - or for
   a property you own: HOLD / SELL at next exit window / ADD MORE.
 * Indian stocks (NSE/BSE): fundamentals + technicals from your data,
   BUY / HOLD / SELL / WAIT / AVOID, entry, stop-loss, targets,
   quantity for 1% risk, expected return range, holding style.
 * Forex: trade plan with lot size for 1% risk, or NO TRADE.

 WHAT TO PASTE: open  prompts/DATA-TEMPLATES.txt , copy the template
 you need into the chat and fill in the numbers.

 How to use it well:
 * It is OFFLINE. It cannot open getstake.com or see live prices,
   rates or news. Paste the numbers yourself: property price, gross
   yield, fees, service charges, your budget / forex pair, price,
   timeframe, highs/lows, news, account size.
 * NO AI CAN PREDICT MARKETS 100%. It gives bullish / base / bearish
   scenarios with probabilities, a CONSIDER / WAIT / AVOID or a trade
   plan (or NO TRADE), and a confidence level. That is by design.
 * Leave "thinking" ON (don't use the "fast" option) for money
   questions - in testing, fast mode made arithmetic mistakes that
   thinking mode got right. Thinking answers take longer (about
   1-2 minutes with a graphics card, several minutes on CPU only).
 * It is a small 4B model: ALWAYS re-check the maths (yield, pip
   value, lot size, risk-reward) before acting. Double-click
   CALCULATOR.html on this drive - it opens in your browser (offline)
   and does the exact maths for Stake property returns, Indian stock
   position size / targets / profit-loss, and forex lot size.
 * It is not a financial advisor. Final decisions are yours.

------------------------------------------------------------------
 WHAT'S INSIDE
------------------------------------------------------------------

 models/Qwen3.5-4B-Q4_K_M.gguf   the AI model (Qwen3.5 4B, 4-bit, 2.6 GB)
 prompts/system-prompt.txt       the Investment Research Assistant rules
 prompts/DATA-TEMPLATES.txt      copy-paste question templates
 CALCULATOR.html                 exact offline calculator (any browser)
 MOOD-CHAT.html                  colourful chat page: the background changes
                                 with the topic and mood (start the AI first,
                                 then double-click this file)
 models/mmproj-F16.gguf          image understanding add-on (lets you
                                 attach pictures in the chat). Delete it
                                 to save 0.6 GB and some RAM.
 engine/                         llama.cpp engine for every OS
 Qwen3.8/                        the official QwenLM/Qwen3.8 GitHub repo
 START-*                         the start files above

 WHY NOT QWEN3.8 ITSELF?
   The Qwen3.8 GitHub repo only contains documentation - no model.
   The Qwen3.8 models are 27B and 2.4T parameters; even the most
   compressed Qwen3.8-27B file is 5.8 GB, bigger than this 4 GB drive.
   Qwen3.5-4B is the official model from the same family (Qwen3.8 is
   built on the Qwen3.5 architecture) and the best quality that fits.

------------------------------------------------------------------
 REQUIREMENTS / TIPS
------------------------------------------------------------------

 * RAM: 8 GB or more recommended (the model uses about 4 GB).
 * Speed: runs on any CPU. A graphics card is used automatically
   if available (Vulkan on Windows/Linux, Metal on Mac).
 * First start on a Mac/Linux computer unpacks the engine
   (about 50 MB) into your user cache folder; later starts are faster.
 * Don't unplug the USB drive while the AI is running.
 * Chat memory (context) is 16384 tokens. Longer:  set QWEN_CTX=32768
   (Windows) or  QWEN_CTX=32768 bash START-LINUX.sh   (uses more RAM).
   Start a new chat when a conversation gets long.
 * Other apps can use it as an OpenAI-compatible API at
       http://127.0.0.1:8080/v1

 USE A DIFFERENT MODEL
   Put any other .gguf model into the models/ folder and remove the
   old one (the start files use the first .gguf they find). If you
   switch models, also delete mmproj-F16.gguf (it only fits Qwen3.5-4B).

 COMPRESSION
   Don't zip/compress these files. The model is already compressed
   (4-bit): zipping saves only 0.3% and it can't run while zipped.

 USB FORMAT
   This drive is NTFS. Windows and Linux read/write it; macOS can only
   read it (that's enough to run the AI). If you want macOS to write
   to it too, back up the files, format the drive as exFAT, and copy
   everything back.

------------------------------------------------------------------
 CREDITS / LICENSES
------------------------------------------------------------------
 Model:  Qwen3.5-4B by Qwen Team, Alibaba (Apache 2.0)
         GGUF file from huggingface.co/unsloth/Qwen3.5-4B-GGUF
 Engine: llama.cpp (MIT) - github.com/ggml-org/llama.cpp
