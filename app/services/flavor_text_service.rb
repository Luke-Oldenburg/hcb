# frozen_string_literal: true

class FlavorTextService
  include ActionView::Helpers::NumberHelper
  include SeasonalHelper

  def initialize(user: nil, env: Rails.env, deterministic: true)
    @user = user
    @env = env
    @seed = deterministic ? Time.now.to_i / 5.minutes : Random.new_seed
    @random = Random.new(@seed)
  end

  def generate
    return development_flavor_texts.sample(random: @random) if @env == "development"
    return holiday_flavor_texts.sample(random: @random) if winter?
    return @random.rand > 0.5 ? spooky_flavor_texts.sample(random: @random) : flavor_texts.sample(random: @random) if fall? # ~50% chance of spookiness
    return birthday_flavor_texts.sample(random: @random) if @user&.birthday?

    in_frc_team = @user&.events&.exists?(category: Event.categories["robotics team"])

    if in_frc_team
      (flavor_texts + frc_flavor_texts).sample(random: @random)
    else
      flavor_texts.sample(random: @random)
    end
  end

  def development_flavor_texts
    [
      "<s>Hack the Bank Mode</s>",
      "Development Mode",
      "super secret admin mode",
      "Puts the 'dev' in 'financially devious'!",
      "Rails.env.fun?",
      "Let's rewrite HCB in #{Faker::ProgrammingLanguage.name}!"
    ]
  end

  def birthday_flavor_texts
    [
      "Happy birthday! #{['🎂', '🎈', '🎉', '🥳'].sample(random: @random)}",
      "<a href='https://www.youtube.com/watch?v=XNV2EyC1NrQ' target='_blank' style='color: inherit'>happy birthday</a>".html_safe,
      "herpy derpday",
      "<a href='https://www.youtube.com/watch?v=1G9iEvQYM4I&t=3s' target='_blank' style='color: inherit'>wahoo!</a>".html_safe,
      "it’s the birthday (boy|girl|person|dinosaur)!",
      "#{%w[🦩 🕊 🦅 🦆 🐓 🦤 🦉 🦃 🐣].sample(random: @random)} harpy bird-day!"
    ]
  end

  def holiday_flavor_texts
    [
      *(["<a href='https://hack.af/hcb-stickers?#{URI.encode_www_form "prefill_Recipient Name": @user.name, "prefill_Login Email": @user.email, prefill_Organization: @user.events.first&.name}' target='_blank' style='color: inherit'>Want a gift?</a>".html_safe] if @user),
      *(["<a href='https://hack.af/hcb-stickers?#{URI.encode_www_form "prefill_Recipient Name": @user.name, "prefill_Login Email": @user.email, prefill_Organization: @user.events.first&.name}' target='_blank' style='color: inherit'>A present, from us to you</a>".html_safe] if @user),
      "Hacky Holidays",
      "let there be snow",
      "ho ho ho ho",
      "where r my cookies?",
      "holiday edition",
      "santa edition",
      "🎅🏻",
      "Walking in a winter hackerland...",
      "🦌🦌🦌🦌🦌🦌🦌🦌🛷🎅🎁",
      "fresh snow for $0.99!",
      "build me a snow castle",
      "build me a snow man",
      "bake me cookies",
      "i want a candy cane",
      "is that Olaf?",
      "did you mean, 'hacky holidays!'",
      "didja mean hacky new year?",
      "<a href='https://santatracker.google.com/' target='_blank' style='color: inherit'>Santa's on the way!</a>".html_safe,
      "dashing through the snow",
      "defrosting...",
      "send snow photos to hcb@hackclub.com",
      "Dasher, Dancer, Prancer, Vixen,<br/>Comet, Cupid, Donner, Blitzen".html_safe,
      "Recommended by Santa",
      "Recommended by Santa's elves",
      "Built by Santa's elves",
      "Built by Santa's elves at Hack Club",
      "Built by Santa's elves at the North Pole",
      "Handcrafted by Santa's elves",
      "feelin' the holiday spirit yet?",
      "To the North Pole!",
      "Hot choco waiting for ya",
      "Built with Ruby on Rails, React, and holiday cheer",
      "u seein' the snow outside?",
      "Dear Santa...",
      "where's my gingerbread house",
      "makin' that money snow"
    ]
  end

  def spooky_flavor_texts
    [
      "Spooky edition",
      "Boo!",
      "Trick or treat!",
      "👻",
      "🧛",
      "🎃",
      "Pumpkin spice is the pumpkin spice of life."
    ]
  end

  def frc_flavor_texts
    [
      "Built by someone from team ##{[1759, 8724, 461, 6763, 1519].sample(random: @random)}!",
      "Safety FIRST!",
      "Safety glasses == invincible",
      "Stop! Where are your safety glasses?",
      "something something ‘gracious professionalism’",
      "help I’ve run out of FIRST puns",
      "do the robot!",
      "It’s not battlebots mom!",
      "I heard next year is a water game",
      "Did you bring enough #{%w[zip-ties ductape].sample(random: @random)}?",
      "Duct tape, ductape, duck tape",
      "🦆 📼",
      "Build season? HCB season!",
      "Build season already?"
    ]
  end

  def flavor_texts
    [
      "The hivemind known as HCB",
      "How often does time happen?",
      "To an extent",
      "A cloud full of money",
      "Hack Club's pot of gold",
      "A sentient stack of dollars",
      "The Hack Club Federal Reserve",
      "money money money money money",
      "A cloud raining money",
      "A pile of money in the cloud",
      "Hack Club Smoothmunny",
      "Hack Club ezBUCKS",
      "Hack Club Money Bucket",
      "A mattress stuffed with 100 dollar bills", # this is the max length allowed for this header
      "Hack Club Dollaringos",
      "The Hack Foundation dba The Dolla Store",
      "Hack on.",
      "Open on weekends",
      "Open on holidays",
      "please don't hack",
      "HCB– Happily Celebrating Bees",
      "HCB– Hungry Computer Bison",
      "HCB– Huge Cellophane Boats",
      "HCB– Hydrofoils Chartered by Bandits",
      "The best thing since sliced bread",
      "Hack Club Bink",
      "Hack 👏 Club 👏 B--- 👏",
      "💻 ♣ 🏦",
      "aka Hack Bank",
      "aka Hank",
      "AKA dolla dolla billz",
      "AKA the nonprofit-atorium",
      "Open late",
      "From the makers of Hack Club",
      "Now in color!",
      "Filmed on location",
      "From the makers of HCB",
      "Soon to be a major cryptocurrency!",
      "As seen on the internet",
      "👏 KEEP 👏 YOUR 👏 RECEIPTS 👏",
      "Money: collect it all!",
      "Help, I'm trapped in the internet!",
      "Most viewed site on this domain!",
      "Coming to a browser near you",
      "Hand-crafted by our resident byte-smiths",
      "B O N K",
      "#{@random.rand 4..9}0% bug free!",
      "#{@random.rand 1..4}0% fewer bugs!",
      "Ask your doctor if HCB is right for you",
      "Now with an&nbsp;<a href='https://hcb.hackclub.com/docs/api/v3'>API</a>!".html_safe,
      "<a href='https://hcb.hackclub.com/docs/api/v3'>README</a>".html_safe,
      "Read the&nbsp;<a href='https://hcb.hackclub.com/docs/api/v3'>docs</a>!".html_safe,
      'Now with "code"',
      "Closed source!",
      "Finally complete!",
      "Internet enabled!",
      "It's finally here!",
      "It's finished!",
      "Holds lots of cents",
      "It just makes cents",
      "By hackers for hackers",
      "Over 100 users!",
      "Over 20 accounts!",
      "Over $2,000,000 served!",
      "One of a kind!",
      "Reticulating splines...",
      "Educational!",
      "Don't use while driving",
      "Support local businesses!",
      "Take frequent breaks!",
      "Technically good!",
      "That's Numberwang!",
      "The bee's knees!",
      "Greater than the sum of its transactions!",
      "Greater than the sum of its donations!",
      "Greater than the sum of its invoices!",
      "Operating at a loss since 2018!",
      "The sum of its parts!",
      "Does anyone actually read this?",
      "Like and subscribe!",
      "Like that smash button!",
      "it protec, and also attac, but most importantly it pay fees back",
      "it secures the bag",
      "Protec but also attac",
      "As seen on hcb.hackclub.com",
      "As seen on hackclub.com",
      "2 cool 4 scool",
      "Now running in production!",
      "put money in computer",
      "TODO: get that bread",
      "Coming soon to a screen near your face",
      "Coming soon to a screen near you",
      "As seen on the internet",
      "Operating at a loss so you don't have to",
      "Made by a non-profit for non-profits",
      "By hackers, for hackers",
      "It holds money!",
      "uwu, notices your ledger",
      "uwu, notices your balance",
      "uwu, notices your big data",
      "uwu",
      "owo",
      "ovo",
      "(◕‿◕✿)",
      "Red acting kinda sus",
      "An important part of this nutritional breakfast",
      "By people with money, for people with money",
      'Made using "money"',
      "Chosen #1 by dinosaurs everywhere",
      "Accountants HATE him",
      "Congratulations, you are the #{number_with_delimiter(10**@random.rand(1..5))}th visitor!",
      "All the finance that's fit to print",
      "You've got this",
      "Don't forget to drink water!",
      "Putting the 'fun' in 'refund'",
      "Putting the 'fun' in 'fundraising'",
      "Putting the 'do' in 'donate'",
      "Putting the 'based' in 'accrual-based accounting'",
      "Putting the 'profit' in 'nonprofit'",
      "Putting the 'sus' in 'financial sustainability'",
      "Putting the 'fun' in 'underfunded'",
      "Donation nation",
      "To TCP, or UDP, that is the question",
      "Now with 0 off-by-one errors!",
      "Initial commit: get that bread",
      "git commit -m 'cash money'",
      "git commit -m 'get that bread'",
      "git commit --amend '$$$'",
      "git add ./cash/money",
      "Wireframed with real wire!",
      "Made from 100% recycled pixels",
      "💖🙌💅🙌💖💁‍♀️💁‍♀️😂😂😂",
      "Open on weekdays!",
      "Open on #{Date.today.strftime("%A")}s",
      "??? profit!",
      "Did you see the price of #{%w[Ðogecoin ₿itcoin Ξtherium].sample(random: @random)}?!",
      "Guess how much it costs to run this thing!",
      "Bytes served fresh daily by Heroku",
      "Running with Ruby on Rails #{Rails.gem_version.canonical_segments.first}",
      "Running on Rails on Ruby",
      "Try saying that 5 times fast!",
      "Try saying it backwards 3 times fast!",
      "Now with 0% interest!",
      "0% interest, but we still think you're interesting",
      "Your project is interesting, even if it gets 0% interest",
      "Achievement unlocked!",
      "20,078 lines of code",
      "Now you have two problems",
      "It's #{%w[collaborative multiplayer].sample(random: @random)} #{%w[venmo cashapp paypal finance banking].sample(random: @random)}!",
      "Fake it till you make it!",
      "Your move, Robinhood",
      "If you can read this, the page's status code is 200",
      "If you can read this, the page has loaded",
      "Now go and buy yourself something nice",
      "[Insert splash text here]",
      "<img src='https://cloud-cno1f4man-hack-club-bot.vercel.app/0zcbx5dwld8161.png' style='transform:translateX(-1rem);width:2rem;height:auto;margin-right:-1.4em;'>".html_safe,
      "Absolutely financial!",
      "Positively financial!",
      "Financially fantastic!",
      "Financially positive!",
      "Condemned by Wall Street",
      "Condemned by the finance pope",
      "Condemned by the Space Pope",
      "Condemned by the sheriff of money",
      "Checkmate, Capitalists!",
      "all your bank are belong to us",
      "USD: U SEEING DIS?",
      "Starring: You",
      "Coded on location",
      "The bank that smiles back!",
      "*technically not a bank*",
      "...or was it?",
      "Where no finance has gone before!",
      "Where no money has gone before!",
      "Voted “3rd”",
      "You are now breathing manually",
      "If you can read this, thanks!",
      "(or similar product)",
      "[OK]",
      "tell your parents it's educational",
      "You found the 3rd Easter egg on the site",
      "A proud sponsor of fiscal #{%w[things thingies stuff].sample(random: @random)}",
      "Now with 10% more hacks!",
      "Now with more clubs!",
      "Please stow your money in the upright position",
      "you may now assume the financial position",
      "The best site you’re using right now",
      "no u",
      "The FitnessGram™ Pacer Test is a multistage aerobic capacity test that progressively gets more difficult as it continues",
      "It Is What It Is",
      "est. some time ago",
      "Ya like jazz?",
      "no hack, only bank",
      "Insert token(s)",
      "Receipts or it didn't happen",
      "Carbon positive!",
      "We put the 'dig it' in 'digital'",
      "Made in 🇺🇸",
      "Your move IRS!",
      "The buck stops here",
      "Hack Club Moneybucks",
      "If you know, you know",
      "We put the 'ants' in 'pants'",
      "We used this&nbsp;<a href='https://zephyr.hackclub.com' target='_blank'>to buy a train</a>".html_safe,
      "🚂 choo choo!",
      "To the moon! 🚀",
      "Do Only Good Everyday",
      "Much #{%w[happy cool fun].sample(random: @random)}. wow!",
      "Very #{%w[bank currency].sample(random: @random)}. wow!",
      "Such #{%w[internet fascinate bank hack].sample(random: @random)}. wow!",
      "So #{%w[currency bank].sample(random: @random)}. wow!",
      "Many #{%w[excite amaze].sample(random: @random)}. wow!",
      "JavaScript brewed fresh daily",
      "It's our business doing finance with you",
      "Flash plugin failed to load",
      "Cash, checks, and cents, oh my!",
      "ACH, checks, and credit, oh my!",
      "Debit, she said",
      "U want sum bank?",
      "* not #{%w[banc banq].sample(random: @random)}",
      "Our ledger's thicker than a bowl of oatmeal",
      "receptz plzzzz",
      "Reciepts? Receipts? Recepts?",
      "Receipts are kinda like a recipe for money",
      "Receipts are kinda like a recipe for a nonprofit",
      "Receipts are kinda like a recipe for losing money",
      "Check the back of this page for an exclusive promo code!<!--\n\n\n\n\n\n\n\n          Use promo code STICKERSNOW for free HCB stickers.\n\n          (Alternatively, you could just get some here: https://hack.af/hcb-stickers)\n\n\n\n\n\n\n\n          -->".html_safe,
      "You've found the 5th easter egg on the site!",
      "Happiness > Wealthiness, but I didn't tell you that",
      "A wallet is fine too",
      "A penny saved...",
      "check... cheque... checkqu?",
      "1...2...3... is this thing on?",
      "Welcome to #{%w[cash money].sample(random: @random)} town, population: you",
      "The buck starts here",
      "So... what's your favorite type of pizza?",
      "<span style='font-size: 2px !important'>If you can read this you've got tiny eyes</span>".html_safe,
      "Page loaded in: < 24 hrs (I hope)",
      "Old and improved!",
      "Newly loaded!",
      "Refreshing! (if you keep hitting ctrl+R)",
      "Recommended by people somewhere!",
      "Recommended by people in some places!",
      "Recommended by non-profits on this site!",
      "Recommended by me!",
      "Recommended by Hack Club!",
      "Recommended by the recommend-o-tron 3000",
      "Recommended! (probably)",
      "We don't accept tips, but we do take advice!",
      "Please stow your money in the upright and locked position",
      "Can't spend what you don't have!",
      "You can ac-count on us!",
      "We put the 'count' in 'accounting'!",
      "bank is such a weird word... bank bank bank",
      "bank baynk baynik banek bake",
      "Have you ever just said a word so much it loses it's meaning?",
      "Teamwork makes the dreams work!",
      "Teamwork makes the memes work!",
      "Dream work makes the memes work!",
      "Meme work makes the team work!",
      "Don't let your dreams be memes!",
      "<em>Vrooooooommmmmmm!</em>".html_safe,
      "Loaded in #{@random.rand(10..35)}ms... jk– i don't actually know how long it took",
      "Loaded in #{@random.rand(10..35)}ms... jk– i can't count",
      "Turns out it's hard to make one of these things",
      "Look ma, no articles of incorporation!",
      "Task failed successfully!",
      "TODO: come up with some actual jokes for this box",
      "asdgfhjdk I'm out of jokes",
      "asdgfhjdk I'm out of #{%w[money cash bank finance financial].sample(random: @random)} puns",
      "Send your jokes to hcb@hackclub.com",
      "Cha-ching!",
      "Hey there cutie!",
      "You're looking great today :)",
      "Great! You're here!",
      "No time to explain: #{%w[quack bark honk].sample(random: @random)} as loud as you can!",
      "Please see attached #{%w[gif avi mp3 wav zip].sample(random: @random)}",
      "Cont. on page 42",
      "See fig. 42",
      "<span class='hide-print'>Try printing this, I dare you</span><span class='hide-non-print'>Gottem!</span>".html_safe,
      "<em>SUPREME</em>".html_safe,
      "You need to wake up",
      "you need to wake up! Pinch yourself",
      "stop dreaming, you need to wake up!",
      "The only bank brave enough to say '#{%w[sus poggers pog oops uwu].sample(random: @random)}'",
      "Fees lookin pretty sus",
      "Are you suuuuure you aren't a robot?",
      "#{%w[laugh cry smile giggle smirk].sample(random: @random)} here if you aren't a robot",
      "Show emotion here if you aren't a robot",
      "<a href='/robots.txt' target='_blank'>Click here if you are a robot</a>".html_safe,
      "Robot?&nbsp;<a href='/robots.txt' target='_blank'>Click here</a>".html_safe,
      "Your ad here!",
      "Make sure your homework is submitted and readable! 👀",
      "What the dollar doin?",
      "Did you mean \"Hack Club Bonk\"?",
      "Did you mean \"Hack Club is jank\"?",
      "Did you mean \"<a href='https://zephyr.hackclub.com' target='_blank'>Hack Club Train</a>\"?".html_safe,
      "Are you feeling lucky?",
      "Not our fault if it ain't in the vault!",
      "...and you can take that to the bank",
      "Hello&nbsp;<span class='md-hide lg-hide'>tiny</span><span class='sm-hide xs-hide'>large</span>-screened person!".html_safe,
      "👀&nbsp;<span class='md-hide lg-hide hide-print'>📱</span><span class='sm-hide xs-hide hide-print'>🖥</span><span class='hide-non-print'>🖨</span>".html_safe,
      "Do you have enough money? I'm positive!",
      "Ever just wonder... why?",
      "asljhdjhakshjdahkdshaksdhaks",
      "Birds aren't real!",
      "Wahoo! 🐟",
      "Redstone update out now!",
      "financial edition",
      "educational edition",
      "non-profit edition",
      "non-educational edition",
      "Where's the money lebowski?!",
      "We put the 'poggers' in 'taxes' (there isn't any)",
      "We put the 'fun' in 'accrual-based accounting' (there isn't any)",
      *(["<a href='https://hack.af/hcb-stickers?#{URI.encode_www_form "prefill_Recipient Name": @user.name, "prefill_Login Email": @user.email, prefill_Organization: @user.events.first&.name}' target='_blank' style='color: inherit'>Want stickers?</a>".html_safe] if @user),
      "🐨 Koalaty banking",
      "If money doesn’t grow on trees, then why do banks have branches?",
      "I was gonna tell a Bank joke, but ran out of interest",
      "If money talks, why do we need bank tellers?",
      "We’ll be here all week",
      "Honk club <img src='https://cloud-1kf8h2v89-hack-club-bot.vercel.app/1goose-honk-right-intensifies.gif' style='height:1.25em;margin-left:0.5em;'/>".html_safe,
      "Handle with care",
      "This side up",
      "if it makes sense it’ll make dollars",
      "<a href='https://www.dinosaurbbq.org' target='_blank' style='color: inherit'>dinosaurbbq.org</a>".html_safe,
      "<a href='/my/settings#security-keys'>☝️ You can sign in with your fingerprint!</a>".html_safe,
      "Totally fungible!",
      "For Hack Clubbers everywhere",
      "<a href='https://cloud-g3k0oo8ci-hack-club-bot.vercel.app/0img_7439.mp4' target='_blank'>Now a currency?</a>".html_safe,
      "Not responsible for any major financial collapse!",
      "In today’s economy?!",
      "Send us your best haiku!",
      "«⋄⇠◇«─◆─»⇢$$$⇠«─◆─»◇⇢⋄»",
      "¸¸.•*$*•.¸¸¸.•*$*•.¸¸¸.•*$*•.¸¸¸.•*$*•.¸",
      "◥◤◢◤◢$$$◣◥◣◥◤",
      "money see, money do!",
      "fund no evil",
      "non-profit doesn’t mean no profit!",
      "0 days since last accident",
      "teen built, teen approved!",
      "a #{%w[megabyte megabit].sample(random: @random)} of #{%w[mulah money].sample(random: @random)}",
      "byte me",
      "now only 2 ticks short of a clock cycle!",
      "not running on the <a href='https://github.com/hackclub/the-hacker-zephyr' target='_blank' style='color: inherit'>zephyrnet</a>!".html_safe,
      "not available offline!",
      "as seen online",
      "online only!",
      "hello fellow kids!",
      "we hope you enjoyed your flight with us today!",
      "new strawberry flavor!",
      "same classic taste",
      "you can account on us!",
      "accountants, assemble!",
      "<a href='https://assemble.hackclub.com' target='_blank' style='color: inherit'>we ran our own hackathon on it!</a>".html_safe,
      "<a href='https://assemble.hackclub.com' target='_blank' style='color: inherit'>good enough for us to use!</a>".html_safe,
      "<a href='https://assemble.hackclub.com' target='_blank' style='color: inherit'>dogfooded by us!</a>".html_safe,
      "<strike>Runs on Airtable™</strike>".html_safe,
      "Got a hankering for some bankering?",
      "<marquee scrollamount='5'>💸💸💸</marquee>".html_safe,
      "Wow, that’s a lot of money. Need some help carrying it?",
      "I would rather check my Facebook than face my checkbook.",
      "The only part not outstanding is our balance"
    ]
  end

  private

  # Used by `SeasonalHelper`
  def current_user
    @user
  end

end
