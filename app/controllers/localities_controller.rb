class LocalitiesController < ApplicationController
  def index
    if params[:latitude].blank? || params[:longitude].blank?
      render json: { error: "Required parameters: latitude, longitude" }, status: :no_acceptable
    else
      render json: Locality.by_latitude_and_longitude(params[:latitude], params[:longitude])
    end
  end
end
