require 'resque'
require 'resque_scheduler'
require 'resque_scheduler/server'


Fortuneteller::Application.routes.draw do

  mount Resque::Server.new, at: "/resque"
 
  get "login/login"
  get "main/index"
  get "login/logout"
  post "login/logout"
  post "login/login"
  

  resources :users do
    member do 
      get 'reset_password'
    end
  end
  resources :organizations
  resources :forecasts do
    collection do
      get 'lookup'
      post 'lookup'
    end
  end

  resources :order_lines do
    collection do 
      get 'lookup'
      post 'lookup'
    end
  end
  resources :ship_lines do
    collection do
      get 'lookup'
      post 'lookup'
    end
  end
  resources :inventory_advices
  resources :receipts
  resources :shipment_confirmations
  resources :locations
  resources :location_groups
  resources :product_location_assignments
  resources :inventory_positions do
    resources :inventory_projections
    collection do
      get 'lookup'
      post 'lookup'
    end  
  end
  resources :inventory_exceptions
  resources :location_group_exceptions
  resources :products do
    collection do
      get 'lookup'
      post 'lookup'
    end
  end

  controller :grouping_views do
    get 'product_centric', action: "product_centric" 
    post 'product_centric', action: "product_centric"
    get 'location_centric', action: "location_centric"
    post 'location_centric', action: "location_centric"
    get 'inventory_bucket_view', action: "inventory_bucket_view"
    post 'inventory_bucket_view', action: "inventory_bucket_view"
    get 'multichoose_view', action: "multichoose_view"
    post 'multichoose_view', action: "multichoose_view"
  end

  controller :dashboard do 
    get 'dashboard', action: "index"
  end

  controller :grouped_projections do 
    get 'grouped_projections', action: "index"
    post 'grouped_projections', action: "index"
  end

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  root to: 'main#index'
end
