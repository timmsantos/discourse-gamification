# frozen_string_literal: true

class LeaderboardViewSerializer < ApplicationSerializer
  attributes :personal

  has_one :leaderboard, serializer: LeaderboardSerializer, embed: :objects
  has_many :users, serializer: UserScoreSerializer, embed: :objects

  def leaderboard
    object[:leaderboard]
  end

  def users
    DiscourseGamification::GamificationLeaderboard.scores_for(object[:leaderboard].id, page: object[:page])
  end

  def personal
    DiscourseGamification::GamificationLeaderboard.scores_for(object[:leaderboard].id, for_user_id: object[:for_user_id])
  end
end
