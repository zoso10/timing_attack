Rails.application.routes.draw do
  resource :secrets, only: :show
end
