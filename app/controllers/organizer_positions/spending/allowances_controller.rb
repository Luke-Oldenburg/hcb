module OrganizerPositions
  module Spending
    class AllowancesController < ApplicationController
      before_action :set_organizer_position

      def new
        @spending_allowance = @op.active_spending_control.organizer_position_spending_allowances.build

        authorize @spending_allowance
      end

      def create
        attributes = filtered_params
        attributes[:authorized_by_id] = current_user.id
        @allowance = @op.active_spending_control.organizer_position_spending_allowances.build(attributes)

        authorize @allowance

        if @allowance.save
          flash[:success] = "Spending allowance created."
          redirect_to event_organizer_controls_path organizer_id: @allowance.organizer_position
        else
          render :new, status: :unprocessable_entity
        end
      end

      private

      def set_organizer_position
        @event = Event.friendly.find(params[:event_id])
        begin
          @user = User.friendly.find(params[:organizer_id])
          @op = OrganizerPosition.find_by!(event: @event, user: @user)
        rescue ActiveRecord::RecordNotFound
          @op = OrganizerPosition.find_by!(event: @event, id: params[:organizer_id])
        end
      end

      def filtered_params
        params.permit(:amount, :memo)
      end

    end
  end
end
