not_found_response = proc { [404, { "Content-type" => "application/json" }, ['{"error": "Not found"}']] }

Rails.application.routes.draw do
  resources :localities, only: [:index, :show] do
    collection do
      get :search, to: :search
    end
  end

  get "*path", to: not_found_response
  root to: not_found_response
end
