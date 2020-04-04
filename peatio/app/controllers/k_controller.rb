# frozen_string_literal: true

class KController < ApplicationController
  def index
    data = KService.fetch_k(params[:ex].to_sym, params[:symbol], params[:interval], params[:limit], params[:start_time], params[:end_time])
    render json: data
  end
end
