require 'mechanize'
require 'uri'
require 'phantomjs'
require 'nokogiri'
require 'watir'

class WelcomeController < ApplicationController
	def index
	end

	def resultados
		mechanize = Mechanize.new
		@busqueda = params[:busqueda]
		b = URI.encode(@busqueda)

		@resCultores = Hash.new
		@resMemoria = Hash.new
		@resBN = Hash.new

		puts "Buscando cultores...\n\n"
		pageARPA = mechanize.get('http://arpa.ucv.cl/dic/')
		form = pageARPA.forms.first
		form['buscar'] = @busqueda
		pageARPA = form.submit
		links_cultores = []
		links_cultores << pageARPA.links_with(:href => /id=\d/)
		pageARPA.links_with(:href => /pagina=+\d/).each do |link|
			pageARPA = link.click
			links_cultores << pageARPA.links_with(:href => /id=\d/)
		end
#
		links_cultores.each do |cxp|
			cxp.each do |cultor|
				@resCultores[cultor.text] = "http://arpa.ucv.cl/dic/" + cultor.uri.to_s
			end
		end

		puts "\n\nBuscando en memoriachilena.cl...\n\n"
		browser = Watir::Browser.new :phantomjs
		browser.goto "http://www.memoriachilena.cl/602/w3-propertyvalue-137757.html?_q=offset%3D0%26limit%3D300%26cid%3D502%26keywords%3D"+ b +"%26stageid%3D100%26searchmode%3Dpartial%26pvid_or%3D509%3A158494%2C26262%2C1224%2C616%2C137551"
		begin
			pagina = Nokogiri::HTML.parse(browser.html)
			titulos = pagina.xpath("//div/h4/a")
		end while titulos.length == 0

		titulos.each do |titulo|
			@resMemoria[titulo.attribute("title").to_s] = "http://www.memoriachilena.cl/602/" + titulo.attribute("href").to_s
		end

		puts "\n\nBuscando en el Archivo de la Biblioteca Nacional... \n\n"
		pagina = "http://descubre.bibliotecanacional.cl/primo_library/libweb/action/myAccountMenu.do?vid=BNC"
		pageBN = mechanize.get(pagina)
		form = pageBN.forms()
		form[1].field_with(:name => "prefes(bulkSize)").value = 1000000
		form[1].submit
		pageBN = Nokogiri::HTML.parse(mechanize.get("http://descubre.bibliotecanacional.cl/primo_library/libweb/action/search.do?ct=facet&fctN=facet_domain&fctV=Archivo+de+M%C3%BAsica&rfnGrp=1&rfnGrpCounter=1&dscnt=0&frbg=&scp.scps=scope%3A(bnc_digitool)%2Cscope%3A(bnc_memoria)%2Cscope%3A(bnc_dtlmarc)%2Cscope%3A(BNC)&tab=bnc_tab&dstmp=1460467864295&srt=rank&ct=search&mode=Basic&&dum=true&indx=1&vl(freeText0)=" + b + "&fn=search&vid=BNC").body)
		titulosBN = pageBN.xpath("//div/h2/a")
		titulosBN.each do |titulo|
			if titulo.attribute("href") =~ /http:\/\/descubre.bibliotecanacional.cl.*/
				@resBN[titulo.text.strip] = titulo.attribute("href")
			else
				@resBN[titulo.text.strip] = "http://descubre.bibliotecanacional.cl/primo_library/libweb/action/" + titulo.attribute("href")
			end
		end
	end
end
