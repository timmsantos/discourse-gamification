# frozen_string_literal: true
RSpec.shared_examples "Scorable Type" do

  let(:user) { Fabricate(:user) }
  let(:user_2) { Fabricate(:user) }
  let!(:gamification_score) { Fabricate(:gamification_score, user_id: user.id) }
  let!(:gamification_score_2) { Fabricate(:gamification_score, user_id: user_2.id, date: 2.days.ago) }
  let(:expected_score) { described_class.score_multiplier }

  describe "updates gamification score" do
    let!(:create_score) { class_action_fabricator }

    it "#{described_class} updates scores for today" do
      expect(DiscourseGamification::GamificationScore.find_by(user_id: user.id).score).to eq(0)
      DiscourseGamification::GamificationScore.calculate_scores
      expect(DiscourseGamification::GamificationScore.find_by(user_id: user.id).score).to eq(expected_score)
    end

    it "#{described_class} does not update scores for records with dates older than since_date" do
      expect(DiscourseGamification::GamificationScore.find_by(user_id: user_2.id).score).to eq(0)
      DiscourseGamification::GamificationScore.calculate_scores
      expect(DiscourseGamification::GamificationScore.find_by(user_id: user_2.id).score).to eq(0)
    end
  end
end

RSpec.describe ::DiscourseGamification::LikeReceived do
  it_behaves_like "Scorable Type" do
    let(:post) { Fabricate(:post, user: user) }
    let(:class_action_fabricator) { Fabricate(:post_action, user: user, post: post) }
    # expect score to be 8 because of 1 point for like received, 5 points for topic, 2 points for post
    let(:expected_score) { 8 }
  end
end

RSpec.describe ::DiscourseGamification::LikeGiven do
  it_behaves_like "Scorable Type" do
    let(:post) { Fabricate(:post, user: user) }
    let(:class_action_fabricator) { Fabricate(:post_action, user: user, post: post, post_action_type_id: 1) }
    # expect score to be 8 because of 1 point for like given, 5 points for topic, 2 points for post
    let(:expected_score) { 8 }
  end
end

RSpec.describe ::DiscourseGamification::UserInvited do
  it_behaves_like "Scorable Type" do
    before do
      stub_request(
        :get,
        "http://local.hub:3000/api/customers/-1/account?access_token&admin_count=0&moderator_count=0"
      ).with(
        headers: {
          'Accept' => 'application/json, application/vnd.discoursehub.v1',
          'Host' => 'local.hub:3000',
          'Referer' => 'http://test.localhost'
        }
      ).to_return(status: 200, body: "", headers: {})
    end

    let(:class_action_fabricator) do
      Fabricate(:invite, invited_by: user) do
        after_create do
          self.update(redemption_count: 1)
        end
      end
    end
  end
end

RSpec.describe ::DiscourseGamification::TimeRead do
  it_behaves_like "Scorable Type" do
    let(:class_action_fabricator) { UserVisit.create(user_id: user.id, time_read: 60, visited_at: Date.today) }
    # expect score to be 2 because of 1 point for time read, 1 point for day visited
    let(:expected_score) { 2 }
  end
end

RSpec.describe ::DiscourseGamification::PostRead do
  it_behaves_like "Scorable Type" do
    let(:class_action_fabricator) { UserVisit.create(user_id: user.id, posts_read: 5, visited_at: Date.today) }
    # expect score to be 2 because of 1 point for post read, 1 point for day visited
    let(:expected_score) { 2 }
  end
end

RSpec.describe ::DiscourseGamification::DayVisited do
  it_behaves_like "Scorable Type" do
    let(:class_action_fabricator) { UserVisit.create(user_id: user.id, visited_at: Date.today) }
  end
end

RSpec.describe ::DiscourseGamification::TopicCreated do
  it_behaves_like "Scorable Type" do
    let(:class_action_fabricator) { Fabricate(:topic, user: user) }
  end
end

RSpec.describe ::DiscourseGamification::PostCreated do
  it_behaves_like "Scorable Type" do
    let(:class_action_fabricator) { Fabricate(:post, user: user) }
    # expect score to be 7 because of 5 points for topic, 2 points for post
    let(:expected_score) { 7 }
  end
end
