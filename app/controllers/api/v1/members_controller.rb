module Api::V1
  class MembersController < BaseApiController
    def index
      if params[:point_stats] == 'true'
        data = Member.developers
        serializer = Api::V1::MemberSerializer
        meta = {
          last_sync_time: SyncRecord.latest_sync_time(:all_data),
          current_sprint_name: Sprint.current_sprint_name
        }
      else
        data = Member.all
        serializer = Api::V1::MemberWithoutPointsSerializer
        meta = { job_profiles: Member.job_profiles.hash }
      end
      render json: data, each_serializer: serializer, meta: meta
    end

    def update
      member = Member.find(params[:data][:id])
      if member.update_attributes(member_params)
        render json: member, serializer: Api::V1::MemberWithoutPointsSerializer
      else
        render json: member.json_api_format_errors, status: 422
      end
    end

    private

    def member_params
      params.require(:data).permit(attributes:
        [:full_name, :user_name, :expected_points, :job_profile])
    end
  end
end
