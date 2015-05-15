# encoding: UTF-8
require 'mechanize'
require 'date'
require 'json'
$stdout = File.open('statistic.txt', 'w')

lvl1_names = []
global_count = 0
group_count = 0
lvl1_count = {}
image_min = [8,""]
image_max = [0,""]
image_empty = 0
image_all = [0,0]  # [0] - количество изображений, [1] - вес изображений

agent = Mechanize.new
page = agent.get("http://prostoudobno.ru/")

# Получаем все ссылки, удовлетворяющие регулярному выражению
cat_1lvl_links = page.links_with(href: %r{Интернет/Доставка})

# Получаем массив имен групп первого уровня
cat_1lvl_links.each do |name|
  lvl1_names << name.text
end

# Проходя по каждой из ссылок первого уровня выводим её заголовок,
# кликаем на неё и выводим заголовки групп второго уровня.
# Затем выводим товары в этой подгруппе, путь загрузки и имя картинки.

cat_1lvl_links.each  do |name|

  print "===== " + name.text + " =====" + "\n"
  lvl1_name = name.text
  lvl1_names << lvl1_name

  cat_2lvl = page.link_with(text: lvl1_name).click

  cat_2lvl.links_with(href: %r{Интернет/Доставка}).each do |link|

    if lvl1_names.include?(link.attributes["title"]) != true

      if link.attributes["title"].nil? != true

        if link.attributes["href"].include?("limit") != true

          print "== " + link.attributes["title"] + " =="
          print "\n\n"

          if cat_2lvl.link_with(text: link.attributes["title"]).nil? != true

            cat_3lvl = cat_2lvl.link_with(text: link.attributes["title"]).click

            products = cat_3lvl.search(".browseProductContainer")

            products.each do |product|

            print product.at(".productname").text.strip
            print "\n"
            path = "/home/alex/Projects/parser/images/" + Time.now.usec.to_i.to_s + "_" + rand(10000000).to_s
            print path
            print "\n"
            image = product.at(".browseProductImage")
            agent.get(image.attributes["src"]).save path
            print "\n"

            size = File.size(path)

            if size == 0
              image_empty = image_empty + 1 else
              if size > image_max[0]
                image_max[0] = size
                image_max[1] = product.at(".productname").text.strip
                else
                if size < image_min[0]
                  image_min[0] = size
                  image_min[1] = product.at(".productname").text.strip
                end
              end
            end

            if size != 0
              image_all[0] = image_all[0] + 1
              image_all[1] = image_all[1] + size
            end

            group_count = group_count + 1

            global_count = global_count + 1

            end
          end
        end
      end
    end
  end

  lvl1_count[name.text] = group_count

  group_count = 0

end

$stdout = STDOUT

print "Статистика по группам:\n\n"

lvl1_count.each do |group|
  print group[0].to_s + "    -     " + group[1].to_s
  print "   -   " + ((100.0 / global_count) * group[1]).to_s + "%\n"
end

print "\n\nПроцент товаров, для которых на сайте присутствовало изображение: "
print (100.0 - (100.0 / image_all[0]) * image_empty).to_s + "%\n\n"

print "Средний размер файла-изображения: " + ((image_all[1] / image_all[0]) / 1024).to_s + "кБ"

print "\n\nМаксимальный размер файла-изображения - " + (image_max[0]/1024).to_s + "кБ, "
print "у товара - " + image_max[1]

print "\n\nМинимальный размер файла-изображения - " + (image_min[0]/1024).to_s + "кБ, "
print "у товара - " + image_min[1]



