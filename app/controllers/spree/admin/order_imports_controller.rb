module Spree
  module Admin
    class OrderImportsController < BaseController

      def index
        @order_import = Spree::OrderImport.new
      end

      def show
        @order_import = Spree::OrderImport.find(params[:id])
        @orders = @order_import.orders
      end

      def create
        @order_import = Spree::OrderImport.create(order_import_params)
        @order_import.import_data!
        # ImportOrdersJob.perform_later(@order_import)
        # flash[:notice] = t('order_import_processing')
        redirect_to admin_order_imports_path
      end

      def destroy
        @order_import = Spree::OrderImport.find(params[:id])
        if @order_import.destroy
          flash[:notice] = t('delete_order_import_successful')
        end
        redirect_to admin_order_imports_path
      end

      private
        def order_import_params
          params.require(:order_import).permit!
        end
    end
  end
end
