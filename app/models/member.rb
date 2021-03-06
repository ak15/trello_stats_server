class Member < ActiveRecord::Base
  as_enum :job_profile, developer: 0, tester: 1, others: 2
  as_enum :role, normal_user: 0, team_lead: 1, admin: 2


  has_one  :user
  has_many :card_members
  has_many :cards, through: :card_members
  has_many :point_stats
  has_many :leaves, -> { merge(Leave.default_scoped) }
  has_many :leaves_updated_by_member, class: 'Leave', foreign_key: 'last_updated_by'

  scope :id_equals, -> (member_ids) { where(id: member_ids) }

  default_scope { order(:full_name) }

  def admin_or_team_lead?
    admin? || team_lead?
  end

  class << self
    def save_member_to_db
      board.members.each do |trello_member|
        find_or_create_by(trello_id: trello_id) do |member|
          member.full_name = trello_member.full_name
          member.user_name = trello_member.username
        end
      end
    end
  end

  def point_stats
    points_hash = {expected_points: expected_points_for_current_sprint,
      doing: 0, in_qa: 0, qa_pass: 0, accepted: 0}
    card_members.current_sprint_cards.each do |cm|
      ['doing', 'in_qa', 'qa_pass', 'accepted'].each do |state|
        if cm.card.send("#{state}?")
          points_hash[state.to_sym] += cm.individuals_point
          break;
        end
      end
    end
    points_hash
  end

  def expected_points_for_current_sprint
    points = expected_points.to_i
    if points > 0
      points = points - total_non_working_day_points
    end
    points
  end

  def total_non_working_day_points
    (Holiday.holidays_in_current_sprint + current_sprint_leaves) * expected_points_per_day
  end

  def expected_points_per_day
    expected_points / Sprint::SPRINT_DURATION
  end

  def current_sprint_leaves
    leaves.where("leaves.date": Sprint.current_sprint_date_range).count
  end
end
