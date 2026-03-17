# frozen_string_literal: true

module ApplicationHelper
  def current_nav_item?(input)
    "current" if current_resource?(input)
  end

  def current_resource?(input)
    case input
    in { action:, **nil } then current_resource_match?(action_name, action)
    in { controller:, **nil } then current_resource_match?(controller_name, controller)
    in { controller:, action: } then current_resource?(controller:) && current_resource?(action:)
    end
  end

  def current_resource_match?(value, pattern)
    case pattern
    in { not: ptn } then !current_resource_match?(value, ptn)
    in String | Regexp then value.match?(pattern)
    end
  end

  def app_name_with_logo
    src = image_path("emoji-mechanical-arm.png")
    arm = tag.img(src: src, alt: "", class: "app-emoji", aria: { hidden: true })
    arm_flip = tag.img(src: src, alt: "", class: "app-emoji app-emoji-flip", aria: { hidden: true })
    safe_join([ arm, " Rails Whey App ", arm_flip ])
  end

  def user_initials(user = Current.user)
    user ? user.initials : "?"
  end
end
