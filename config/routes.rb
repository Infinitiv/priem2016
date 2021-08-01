Rails.application.routes.draw do
  devise_for :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  root 'campaigns#index'
  
  namespace :api, defaults: {format: 'json'}, path: '/api' do
    resources :entrant_applications, only: [:show, :create, :update] do
      collection do
        post 'check_email'
      end
      member do
        put 'check_pin'
        put 'remove_pin'
        put 'generate_entrant_application'
        put 'generate_consent_applications'
        put 'generate_withdraw_applications'
        put 'generate_contracts'
        put 'send_welcome_email'
      end
    end
    resources :attachments, only: [:show, :create, :destroy]
    resources 'stats', only: [:show] do
      member do
        get 'entrants'
	get 'registration_dates'
        get 'competitive_groups'
      end
      collection do
        get 'campaigns'
      end
    end
    resources :dictionaries, only: [:index, :show]
    resources :campaigns, only: [:index, :show]
  end
  
  resources :identity_documents, only: [:update, :destroy]
  resources :education_documents, only: [:update, :destroy]
  resources :target_contracts, only: [:update, :destroy]
  resources :other_documents, only: [:destroy]
  resources :olympic_documents, only: [:update, :destroy] do
    member do
      put 'convert_to_other_document'
    end
  end
  resources :tickets, only: [:index, :create] do
    member do
      put 'solve'
    end
  end
  resources :benefit_documents, only: [:update, :destroy] do
    member do
      put 'convert_to_other_document'
    end
  end
  resources :achievements, only: [:create, :update, :destroy]
  resources :marks, only: [:create, :update, :destroy]
  resources :journals, only: [:index, :destroy] do
    member do
      put 'done'
    end
  end
  
  resources :requests, only: [:index, :show, :new, :create, :destroy]
  resources :campaigns do
    member do
      post 'import_admission_volume'
      post 'import_institution_achievements'
    end
  end
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
      post 'competition_lists_to_egpu'
      get 'errors'
      get 'ege_to_txt'
      get 'competition_lists'
      get 'ord_export'
      get 'ord_return_export'
      get 'ord_marks_request'
      get 'ord_result_export'
      get 'ord_access_request'
      get 'target_report'
      get 'competition_lists_to_html'
      get 'competition_lists_ord_to_html'
      get 'entrants_lists_to_html'
      get 'entrants_lists_ord_to_html'
    end
    member do
      get 'touch'
      put 'toggle_original'
      put 'entrant_application_recall'
      put 'toggle_ignore'
      put 'generate_templates'
      put 'approve'
      put 'add_comment'
      delete 'delete_comment'
      delete 'delete_request'
      post 'add_document'
    end
  end
  
  resources :attachments, only: [:show, :destroy]
  
  put 'entrant_applications/:id/competitive_groups/:competitive_group_id/toggle_agreement' => 'entrant_applications#toggle_agreement'
  put 'entrant_applications/:id/competitive_groups/:competitive_group_id/toggle_contract' => 'entrant_applications#toggle_contract'
  put 'entrant_applications/:id/competitive_groups/:competitive_group_id/toggle_competitive_group' => 'entrant_applications#toggle_competitive_group'
  
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
