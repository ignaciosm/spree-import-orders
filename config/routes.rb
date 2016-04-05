Spree::Core::Engine.append_routes do
  namespace :admin do
    resources :order_imports
  end
end
