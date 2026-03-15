# frozen_string_literal: true

module CommentAuthorization
  extend ActiveSupport::Concern

  private

  def comment_author?
    @comment.user_id == Current.user.id
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
