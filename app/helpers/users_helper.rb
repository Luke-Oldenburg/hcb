# frozen_string_literal: true

require "digest/md5"
require "cgi"

module UsersHelper
  def gravatar_url(email, name, id, size)
    name ||= begin
      temp = email.split("@").first.split(/[^a-z\d]/i).compact_blank
      temp.length == 1 ? temp.first.first(2) : temp.first(2).map(&:first).join
    end
    hex = Digest::MD5.hexdigest(email.downcase.strip)
    "https://gravatar.com/avatar/#{hex}?s=#{size}&d=https%3A%2F%2Fui-avatars.com%2Fapi%2F/#{CGI.escape(name)}/#{size}/#{get_user_color(id)}/fff"
  end

  def profile_picture_for(user, size = 24)
    # profile_picture_for works with OpenStructs (used on the front end when a user isn't registered),
    # so this method shows Gravatars/intials for non-registered and allows showing of uploaded profile pictures for registered users.
    if user.nil?
      src = "https://cloud-80pd8aqua-hack-club-bot.vercel.app/0image-23.png"
    elsif Rails.env.production? && (user.is_a?(User) && user&.profile_picture.attached?)
      src = Rails.application.routes.url_helpers.url_for(user.profile_picture.variant(
                                                           thumbnail: "#{size * 2}x#{size * 2}^",
                                                           gravity: "center",
                                                           extent: "#{size * 2}x#{size * 2}"
                                                         ))
    else
      src = gravatar_url(user.email, user.initials, user.id, size * 2)
    end

    src
  end

  def current_user_flavor_text
    [
      "You!",
      "Yourself!",
      "It's you!",
      "Someone you used to know!",
      "You probably know them!",
      "You’re currently looking in a mirror",
      "it u!",
      "Long time no see!",
      "You look great!",
      "Your best friend",
      "Hey there, big spender!",
      "Yes, you!",
      "Who do you think you are?!",
      "Who? You!",
      "You who!",
      "Yahoo!",
      "dats me!",
      "dats u!",
      "byte me!"
    ]
  end

  def avatar_for(user, size = 24, options = {})
    src = profile_picture_for(user, size)

    klasses = ["circle", "shrink-none"]
    klasses << "avatar--current-user" if user == current_user
    klasses << options[:class] if options[:class]
    klass = klasses.join(" ")

    alt = current_user_flavor_text.sample if user == current_user
    alt ||= user&.initials
    alt ||= "Brown dog grinning and gazing off into the distance"

    image_tag(src, options.merge(loading: "lazy", alt:, width: size, height: size, class: klass))
  end

  def user_mention(user, options = {}, default_name = "No User")
    name = content_tag :span, (user&.initial_name || default_name)
    avi = avatar_for user

    klasses = ["mention"]
    klasses << %w[mention--admin tooltipped tooltipped--n] if user&.admin?
    klasses << %w[mention--current-user tooltipped tooltipped--n] if current_user && (user&.id == current_user.id)
    klasses << options[:class] if options[:class]
    klass = klasses.uniq.join(" ")

    aria = if user.nil?
             "No user found"
           elsif user.id == current_user&.id
             current_user_flavor_text.sample
           elsif user.admin?
             "#{user.name} is an admin"
           end

    content = if user&.admin?
                bolt = inline_icon "admin-badge", size: 20
                avi + bolt + name
              else
                avi + name
              end

    content_tag :span, content, class: klass, 'aria-label': aria
  end

  def admin_tools(class_name = "", element = "div", override_pretend: false, **options, &block)
    if options[:if] == false
      yield
    else
      return unless current_user&.admin? || (override_pretend && current_user&.admin_override_pretend?)

      concat("<#{element} class='admin-tools #{class_name}'>".html_safe)
      yield
      concat("</#{element}>".html_safe)
    end
  end

  def creator_bar(object, options = {})
    creator = if defined?(object.creator)
                object.creator
              elsif defined?(object.sender)
                object.sender
              else
                object.user
              end
    mention = user_mention(creator, options, default_name = "Anonymous User")
    content_tag :div, class: "comment__name" do
      mention + relative_timestamp(object.created_at, prefix: options[:prefix], class: "h5 muted")
    end
  end

  def creator_bar_new(object, options = {})
    creator = if defined?(object.creator)
                object.creator
              elsif defined?(object.sender)
                object.sender
              else
                object.user
              end

    content_tag :p, class: "muted m0 p0 #{options[:class]}", style: options[:style] do
      "#{options[:prefix]} by #{creator.initial_name} #{time_ago_in_words object.created_at} ago"
    end
  end

  def user_birthday?(user = current_user)
    user&.birthday?
  end

  private

  def get_user_color(id)
    alphabet = ("A".."Z").to_a
    colors = ["ec3750", "ff8c37", "f1c40f", "33d6a6", "5bc0de", "338eda"]
    colors[id.to_i % colors.length] || colors.last
  end
end
