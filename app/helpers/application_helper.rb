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

  def unread_notification_count
    @unread_notification_count ||= (Current.user&.notifications&.unread&.count || 0)
  end

  def notification_icon(notification)
    case notification.action.to_s
    when /transfer/ then "🔁"
    when /invitation/ then "✉️"
    else "🔔"
    end
  end

  def notification_message(notification)
    n = notification.notifiable
    case notification.action
    when "transfer_requested"
      n.is_a?(TaskListTransfer) ? "#{n.transferred_by.username} wants to transfer list \"#{n.task_list.name}\" to you" : notification.action.humanize
    when "transfer_accepted"
      n.is_a?(TaskListTransfer) ? "Your transfer of \"#{n.task_list.name}\" was accepted" : notification.action.humanize
    when "transfer_rejected"
      n.is_a?(TaskListTransfer) ? "Your transfer of \"#{n.task_list.name}\" was rejected" : notification.action.humanize
    when "invitation_received"
      n.is_a?(Invitation) ? "You've been invited to join #{n.account.name}" : notification.action.humanize
    when "invitation_accepted"
      n.is_a?(Invitation) ? "#{n.email} accepted your invitation" : notification.action.humanize
    else
      notification.action.humanize
    end
  end

  def notification_link(notification)
    n = notification.notifiable
    case notification.action
    when "transfer_requested"
      n.is_a?(TaskListTransfer) ? transfer_path(n.token) : nil
    when "invitation_received"
      n.is_a?(Invitation) ? invitation_path(n.token) : nil
    else
      nil
    end
  end

  def app_name_with_logo
    src = image_path("emoji-mechanical-arm.png")
    arm = tag.img(src: src, alt: "", class: "app-emoji", aria: { hidden: true })
    arm_flip = tag.img(src: src, alt: "", class: "app-emoji app-emoji-flip", aria: { hidden: true })
    safe_join([ arm, " Rails Whey App ", arm_flip ])
  end

  def user_initials(user = Current.user)
    return "?" unless user
    username = user.username.to_s
    return username[0, 2].upcase if username.present?

    email = user.email.to_s
    parts = email.split("@").first.to_s.split(/[._-]/)
    parts.size >= 2 ? "#{parts[0][0]}#{parts[1][0]}".upcase : email[0, 2].upcase
  end
end
