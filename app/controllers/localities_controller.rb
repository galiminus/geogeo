class LocalitiesController < ApplicationController
  def index
    if params[:latitude].blank? || params[:longitude].blank?
      render json: { error: "Required parameters: latitude, longitude" }, status: :not_acceptable
    else
      locality_within = Locality.find_by_latitude_and_longitude(params[:latitude], params[:longitude]).limit(1).first

      locality =
        if locality_within.present?
          locality_within
        else
          Locality.closest_to(params[:latitude], params[:longitude]).limit(1).first
        end

      render json: locality
    end
  end
end
