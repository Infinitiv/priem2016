Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  root 'requests#new'
  
  namespace :api, defaults: {format: 'json'}, path: '/api' do
    resources :entrant_applications, only: [:show]
    resources 'stats' do
      member do
        get 'entrants'
        get 'marks'
      end
      collection do
        get 'campaigns'
      end
    end
  end
  
  resources :requests, only: [:index, :show, :new, :create, :destroy]
  resources :campaigns
  resources :admission_volumes
  resources :distributed_admission_volumes do
    member do
      get 'admission_volume_to_json'
    end
  end
  
  resources :edu_programs
  resources :target_organizations
  resources :competitive_groups do
    member do
      get 'add_education_program'
      get 'remove_education_program'
      get 'add_entrance_test_item'
      get 'remove_entrance_test_item'
    end
  end
  resources :competitive_group_items
  resources :subjects
  resources :target_numbers
  resources :entrance_test_items
  resources :institution_achievements
  resources :entrant_applications do 
    collection do
      post 'import'
      get 'errors'
      get 'ege_to_txt'
      get 'competition_lists'
      get 'ord_export'
      get 'ord_return_export'
      get 'ord_marks_request'
      get 'ord_result_export'
      get 'competition_lists_to_html'
      get 'competition_lists_ord_to_html'
    end
    member do
      get 'touch'
    end
  end
  
  get 'reports/mon'
  
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
end
