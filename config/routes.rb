Rails.application.routes.draw do
  namespace :api, { format: 'json' } do
    resource :amazon_pages do
      member do 
        get :crawl
      end
    end
  end

  # resources :amazon_pages
  root to: 'api/amazon_pages#index'
end
