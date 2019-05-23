class LittleShodan
    def initialize(apikey)
        @apikey = apikey
        @agent = Mechanize.new()
        @count = 0
        @progress_amount = 0
    end

    def host(ip)
        return JSON.parse(@agent.get("https://api.shodan.io/shodan/host/#{ip}?key=#{@apikey}").body())
    end

    def count(query)
        return JSON.parse(@agent.get("https://api.shodan.io/shodan/host/count?query=#{query}&key=#{@apikey}").body())
    end
end

class Aware
    def initialize(shodan_api_key)
        @agent = Mechanize.new
        @shodan = LittleShodan.new(shodan_api_key)
        @ip_db = {}
    end

    def lookup_ip(ip)
        return JSON.parse(@agent.get("https://ipinfo.io/#{ip}").body())
    end

    def parse_csv(filename)
        data = CSV.read(filename).sort!
        @count = data.length
        @progress_amount = 0
        assets = {}

        progressbar = ProgressBar.create(:format => '%a %e %B %p%% %t')

        data.each do |line|
            @progress_amount += 1
            progressbar.progress = (@progress_amount.to_f / @count.to_f) * 100

            if line[0] != "Hostname"
                hostname = line[0]
                if line[1] != nil
                    ip_addresses = line[1].split(", ")
                else
                    ip_addresses = []
                end

                assets[hostname] = {"ip_addresses"=>{}}
                ip_addresses.each do |ip|
                    # puts "scanning #{ip}"
                    if @ip_db[ip]
                        assets[hostname]["ip_addresses"][ip] = @ip_db[ip]
                    else
                        assets[hostname]["ip_addresses"][ip] = lookup_ip(ip)
                        begin
                            shodan_full = {}
                            shodan_res = @shodan.host(ip)
                            shodan_res["ports"].each do |port|
                                shodan_res["data"].each do |data_obj|
                                    if data_obj["port"] == port
                                        if data_obj.key? "product"
                                            shodan_full[port] = {"product"=>data_obj["product"]}
                                        end
                                    end 
                                end
                            end
                            assets[hostname]["ip_addresses"][ip]["shodan"] = shodan_full
                        rescue 
                            assets[hostname]["ip_addresses"][ip]["shodan"] = nil
                        end
                        @ip_db[ip] = assets[hostname]["ip_addresses"][ip]
                    end

                end
            end
        end

        assets.delete("Hostname")
        return assets
    end

    def format_assets(assets)
        @output = ""
        assets.each do |hostname, data|
            @output += hostname.bold + "\n"
            ip_addresses = data["ip_addresses"]
            ip_addresses.each do |ip, data|
                attributes = ["ip", "org", "hostname", "city", "region", "country", "loc", "shodan"]
                attributes.each do |attribute|
                    if !data[attribute]
                        data[attribute] = ""
                    end
                end
                @output += "- #{data["ip"].bold.blue} #{data["org"].light_blue} #{data["hostname"].bold}\n"
                @output += "\t- #{"City:".bold.blue} #{data["city"]}, #{"Region:".bold.blue} #{data["region"]}, #{"Country:".bold.blue} #{data["country"]}, #{"Loc:".bold.blue} #{data["loc"]}\n"
                begin
                    data["shodan"].each do |port, data|
                        @output += "\t- #{port.to_s.bold.blue} #{data["product"].red}\n"
                    end
                rescue
                    #
                end
                @output += "\n"
                
            end
            @output += "\n"
        end
        return @output
    end
end
