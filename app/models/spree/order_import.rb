module Spree
  class OrderError < StandardError; end;
  class ImportError < StandardError; end;
  class OrderImport < ActiveRecord::Base

    has_attached_file :data_file, path: ":rails_root/lib/etc/order_data/data-files/:basename.:extension", url: ":rails_root/lib/etc/order_data/data-files/:basename.:extension"
    validates_attachment :data_file, presence: true, content_type: { content_type: "text/csv" }
    # after_destroy :destroy_orders
    serialize :order_ids, Array

    state_machine initial: :created do
      event :start do
        transition to: :started, from: :created
      end
      event :complete do
        transition to: :completed, from: :started
      end
      event :failure do
        transition to: :failed, from: :started
      end
      before_transition to: [:failed] do |import|
        import.product_ids = []
        import.failed_at = Time.now
        import.completed_at = nil
      end
      before_transition to: [:completed] do |import|
        import.failed_at = nil
        import.completed_at = Time.now
      end
    end

    def orders
      Order.where :number => order_ids
    end

    # def destroy_orders
    #   orders.destroy_all
    # end

    def state_datetime
      if failed?
        failed_at
      elsif completed?
        completed_at
      else
        Time.now
      end
    end
    
    def import_data!(_transaction=true)
        start
        if _transaction
          transaction do
            _import_data
          end
        else
          _import_data
        end
    end

    def _import_data
      begin
        @orders_before_import = Spree::Order.all
        @numbers_of_orders_before_import = @orders_before_import.map(&:number)

        rows = CSV.read(self.data_file.path)
        col = get_column_mappings(rows[0])

        rows[1..-1].each do |row|
          order_information = assign_col_row_mapping(row, col)
          order_information = validate_and_sanitize(order_information)
          next if @numbers_of_orders_before_import.include?(order_information[:order_id])

          order_data = get_order_hash(order_information)
          unless order_information[:order_id].in? order_ids
            order_data[:bill_address_attributes] = order_data[:ship_address_attributes] = get_address_hash(order_information)
            order_data = add_custom_order_fields(order_information, order_data)

            user = Spree::User.find_by_email(order_information[:email]) || Spree::User.new(email: order_information[:email])
            order = Spree::Core::Importer::Order.import(user, order_data)
            if order
              order_ids << order.number 
              after_order_created(order_information, order)
            end
          else
            # code to update more than 1 line items, shipments, payments, adjustments or inventory units
            order = Spree::Order.find_by_number(order_information[:order_id])
            Spree::Core::Importer::Order.create_line_items_from_params(order_data.delete(:line_items_attributes), order) if order_information[:sku]

            unless order_information[:tracking].in? order.shipments.map(&:tracking) or order_information[:tracking].nil?
              # this code creates new shipment if there is a new tracking code
              Spree::Core::Importer::Order.create_shipments_from_params(order_data.delete(:shipments_attributes), order)
            end
            Spree::Core::Importer::Order.create_adjustments_from_params(order_data.delete(:adjustments_attributes), order) if order_information[:adjustment_amount] and order_information[:adjustment_label]
            Spree::Core::Importer::Order.create_payments_from_params(order_data.delete(:payments_attributes), order) if order_information[:payment_method]
            
            # Really ensure that the order totals & states are correct
            order.updater.update
            order.reload
            # Ensure if the inventory units are correct
            Spree::OrderInventory.new(order, order.line_items.last).verify()
            after_order_updated(order_information, order)
          end
        end
      end

      # Finished Importing!
      complete
      return [:notice, "Orders data was successfully imported."]
    end

    private
      # get_column_mappings
      # This method attempts to automatically map headings in the CSV files
      # with fields in the product and variant models.
      # If the headings of columns are going to be called something other than this,
      # or if the files will not have headings, then the manual initializer
      # mapping of columns must be used.
      # @return a hash of symbol heading => column index pairs
      def get_column_mappings(row)
        mappings = {}
        row.each_with_index do |heading, index|
          # Stop collecting headings, if heading is empty
          if not heading.blank?
            mappings[heading.downcase.gsub(/\A\s*/, '').chomp.gsub(/\s/, '_').to_sym] = index
          else
            break
          end
        end
        mappings
      end

      def assign_col_row_mapping(row, col)
        order_information = {}
        col.each do |key, value|
          #Trim whitespace off the beginning and end of row fields
          row[value].try :strip!
          order_information[key] = row[value]
        end
        order_information
      end

      def validate_and_sanitize(order_information)
        # this method can be overiden to include custom logic
        # order_information[:completed_at] = DateTime.strptime(order_information[:completed_at], "%d/%m/%y %H:%M")
        order_information[:completed_at] = order_information[:completed_at] || Time.now
        order_information[:quantity] = order_information[:quantity] || 1
        order_information
      end

      def get_order_hash(order_information)
        {
          number: order_information[:order_id],
          email: order_information[:email],
          completed_at: order_information[:completed_at],
          currency: order_information[:currency],
          channel: order_information[:channel],
          line_items_attributes: [
            {sku: order_information[:sku], quantity: order_information[:quantity], price: order_information[:price], currency: order_information[:currency]}
          ],
          payments_attributes: [
            { amount: order_information[:price], payment_method: order_information[:payment_method], state: order_information[:payment_state], created_at: order_information[:payment_created_at]}
          ],
          adjustments_attributes: [
            {amount: order_information[:adjustment_amount], label: order_information[:adjustment_label]}
          ],
          shipments_attributes: [{
            tracking: order_information[:tracking],
            stock_location: order_information[:stock_location] || 'default',
            shipped_at: order_information[:shipped_at],
            shipping_method: order_information[:shipping_method] || 'default',
            cost: order_information[:shipping_cost],
            inventory_units: [
              { sku: order_information[:sku] }
            ]
          }]
        }
      end

      def get_address_hash(order_information)
        {
          firstname: order_information[:firstname],
          lastname: order_information[:lastname],
          phone: order_information[:phone],
          address1: order_information[:address1],
          address2: order_information[:address2],
          city: order_information[:city],
          state: { 'name'=> order_information[:state] },
          zipcode: order_information[:zipcode],
          country: { 'name'=> order_information[:country]}
        }
      end

      def add_custom_order_fields(order_information, order_data)
        # this method can be overiden to include custom logic
        # eg. order_data[:shipments_attributes] = nil
        order_data[:adjustments_attributes] = nil unless order_information[:adjustment_amount] and order_information[:adjustment_label]
        order_data
      end

      def after_order_created(order_information, order)
        # this method can be overiden to include custom logic
        # eg. order.shipments.first.update(tracking: order_information[:tracking])
        order.cancel if order_information[:status] == "canceled"
      end

      def after_order_updated(order_information, order)
        # this method can be overiden to include custom logic
        # eg. order.shipments.last.ship
      end

  end
end