# frozen_string_literal: true

module UsersHelper
  def notification_filter_links(unread_count:, filter:)
    unread = User::Notification::UNREAD
    invites = User::Notification::INVITES
    transfers = User::Notification::TRANSFERS

    safe_join([
      link_to("All", user_notification_inbox_index_path, class: filter == "all" ? "active" : nil),
      link_to("Unread (#{unread_count})", user_notification_inbox_index_path(filter: unread), class: filter == unread ? "active" : nil),
      link_to("🔁 Transfers", user_notification_inbox_index_path(filter: transfers), class: filter == transfers ? "active" : nil),
      link_to("✉️ Invites",  user_notification_inbox_index_path(filter: invites),   class: filter == invites   ? "active" : nil)
    ], " ")
  end

  def unread_notification_count
    @unread_notification_count ||= (Current.user&.notifications&.unread&.count || 0)
  end

  def notification_icon(notification)
    case String(notification.action)
    when /transfer/ then "🔁"
    when /invitation/ then "✉️"
    else "🔔"
    end
  end

  def notification_message(notification)
    case [ notification.action, notification.notifiable ]
    in [ User::Notification::TRANSFER_REQUESTED, Task::List::Transfer => transfer ]
      "#{transfer.transferred_by.username} wants to transfer list \"#{transfer.task_list.name}\" to you"
    in [ User::Notification::TRANSFER_ACCEPTED, Task::List::Transfer => transfer ]
      "Your transfer of \"#{transfer.task_list.name}\" was accepted"
    in [ User::Notification::TRANSFER_REJECTED, Task::List::Transfer => transfer ]
      "Your transfer of \"#{transfer.task_list.name}\" was rejected"
    in [ User::Notification::INVITATION_RECEIVED, Account::Invitation => invitation ]
      "You've been invited to join #{invitation.account.name}"
    in [ User::Notification::INVITATION_ACCEPTED, Account::Invitation => invitation ]
      "#{invitation.email} accepted your invitation"
    else
      notification.action.humanize
    end
  end

  def notification_link(notification)
    case [ notification.action, notification.notifiable ]
    in [ User::Notification::TRANSFER_REQUESTED, Task::List::Transfer => transfer ]
      account_transfers_response_path(token: transfer.token)
    in [ User::Notification::INVITATION_RECEIVED, Account::Invitation => invitation ]
      account_invitations_acceptance_path(token: invitation.token)
    else
      nil
    end
  end
end
