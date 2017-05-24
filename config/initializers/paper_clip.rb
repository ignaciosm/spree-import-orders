# config/initizlizers/paper_clip.rb

#Paperclip Content Mapping Fix for windows csv files
Paperclip.options[:content_type_mappings] = { csv: 'application/vnd.ms-excel' }