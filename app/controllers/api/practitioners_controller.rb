module Api
  class PractitionersController < ApplicationController
    skip_forgery_protection

    def index
      practitioners = Practitioner.with_specialty(params[:specialty]).in_city(params[:city]).order(:last_name).limit(100)
      render json: practitioners.as_json(only: %i[id first_name last_name specialty city consultation_fee_cents])
    end

    def show
      practitioner = Practitioner.find(params[:id])
      render json: practitioner.as_json(methods: %i[full_name fee])
    end
  end
end
