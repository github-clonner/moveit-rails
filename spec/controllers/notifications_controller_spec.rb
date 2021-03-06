require 'rails_helper'

RSpec.describe NotificationsController, :type => :controller do
  render_views
  describe "GET message" do
  	let(:user) {create(:user)}
  	context "default" do
  		it "returns default notification message for 7 o clock" do
  			get :message, {time: "7", email: user.email, format: :json}

  			expect(response).to be_success
  			responseData = JSON.parse(response.body)
  			expect(responseData["short"]).to eq(I18n.t('notification_messages.default.7oClock.short'))
  			expect(responseData["long"]).to eq(I18n.t('notification_messages.default.7oClock.long'))
  		end
  		it "returns default notification message for 18 o clock (6PM)" do
  			get :message, {time: "18", email: user.email, format: :json}

  			expect(response).to be_success
  			responseData = JSON.parse(response.body)
  			expect(responseData["short"]).to eq(I18n.t('notification_messages.default.18oClock.short'))
  			expect(responseData["long"]).to eq(I18n.t('notification_messages.default.18oClock.long'))
  		end
      it "returns activity empty for default" do
        get :message, {time: "18", email: user.email, format: :json}

        expect(response).to be_success
        responseData = JSON.parse(response.body)
        expect(responseData["activity"]).to eq("")
      end
  	end

  	context "unread bumps" do
  		xit "return message with bump details" do
  			create(:entry, {user_id: user.id, created_at: 2.days.ago})
  			controller.instance_variable_set(:@unread_bumps_count, 1)

  			get :message, {time: "7", email: user.email, format: :json}

  			responseData = JSON.parse(response.body)
  			expect(responseData["short"]).to eq(I18n.t('notification_messages.bumps.short', name: user.name, count: 1))
  		end
  	end

  	context "unread nudges" do 
  		xit "return message with nudge details" do
  			create(:entry, {user_id: user.id, created_at: 50.days.ago})
  			controller.instance_variable_set(:@unread_nudges_count, 2)

  			get :message, {time: "7", email: user.email, format: :json}

  			responseData = JSON.parse(response.body)
  			expect(responseData["short"]).to eq(I18n.t('notification_messages.nudges.short', name: user.name))
  		end
  	end
  end

  describe "POST read" do
  	let(:user) {create(:user)}
  	it "marks as read" do
  		interactions = create_list(:user_interaction, 5, :bump, to_user: user)
  		read_interaction_ids = interactions.map(&:id)

  		post :read, {email: user.email, format: :json}

  		read_interactions = UserInteraction.find(read_interaction_ids)
  		expect(read_interactions.map(&:notification_read).all?).to be_truthy
  	end
  end

  context "GET unread" do
    let(:user) {create(:user)}

    it "return array of unread notifications" do
      interactions = create_list(:user_interaction, 5, :bump, to_user: user)
      interactions.first.update_attributes(notification_read: true)
      unread_interaction_ids = interactions.map(&:id)

      post :unread, {email: user.email, format: :json}

      responseData = JSON.parse(response.body)
      expect(responseData.length).to eq(UserInteraction.where(to_user: user, notification_read: false).count)
    end
  end


  context "GET notifications" do
    let(:from_user) { create(:user) }
    let(:to_user) { create(:user) }

    it "return all user interaction activities" do
      interaction1 = create(:user_interaction, :bump, from_user: from_user, to_user: to_user)
      interaction2 = create(:user_interaction, :bump, from_user: create(:user), to_user: to_user)

      get :index, email: to_user.email, format: :json

      expect(response).to have_http_status :ok 
      responseData = JSON.parse(response.body)["notifications"]
      expect(responseData[0]["activity_type"]).to eq "UserInteraction"
      expect(responseData[0]["activity_json_data"]["id"]).to eq interaction2.id
      expect(responseData[1]["activity_json_data"]["id"]).to eq interaction1.id
    end
  end
end
