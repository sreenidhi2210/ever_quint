Rails.application.routes.draw do
  resources :rooms, only: [:create, :index]

  resources :bookings, only: [:create, :index] do
    post :cancel, on: :member
  end

  get "/reports/room-utilization",
      to: "reports#room_utilization"
end