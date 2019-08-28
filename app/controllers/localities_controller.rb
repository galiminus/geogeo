class LocalitiesController < ApplicationController
  def index
    if params[:latitude].blank? || params[:longitude].blank?
      render json: { error: "Required parameters: latitude, longitude" }, status: :not_acceptable
    else
      render json: Locality.best_match(params[:latitude], params[:longitude])
    end
  end
end
