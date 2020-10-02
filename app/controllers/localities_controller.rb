class LocalitiesController < ApplicationController
  def index
    if params[:latitude].blank? || params[:longitude].blank?
      render json: { error: "Required parameters: latitude, longitude" }, status: :not_acceptable
    else
      render json: Locality.best_matches_by_location(params[:latitude], params[:longitude]).limit(1).first
    end
  end

  def search
    if params[:q].blank? && (params[:latitude].blank? || params[:longitude].blank?)
      render json: { error: "Required parameters: latitude, longitude or q" }, status: :not_acceptable
    else
      scope = Locality

      if params[:q].present?
        scope = scope.best_matches_by_name(params[:q])
      end

      if params[:latitude].present? && params[:longitude].present?
        scope = scope.best_matches_by_location(params[:latitude], params[:longitude])
      end

      render json: scope.limit(25)
    end
  end
end
