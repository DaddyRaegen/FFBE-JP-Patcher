class Data {
  int? version;
  String? updateUrl;
  List<Events>? events;

  Data({this.version, this.updateUrl, this.events});

  Data.fromJson(Map<String, dynamic> json) {
    version = json['version'];
    updateUrl = json['update_url'];
    if (json['events'] != null) {
      events = <Events>[];
      json['events'].forEach((v) {
        events!.add(Events.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['version'] = version;
    data['update_url'] = updateUrl;
    if (events != null) {
      data['events'] = events!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Events {
  String? name;
  String? url;
  String? banner;
  List<String>? files;
  List<String>? payloadFiles;

  Events({this.name, this.url, this.banner, this.files, this.payloadFiles});

  Events.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    url = json['url'];
    banner = json['banner'];
    files = json['files'].cast<String>();
    if (json['payload_files'] != null){
      payloadFiles = json['payload_files'].cast<String>();
    }
    
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['url'] = url;
    data['banner'] = banner;
    data['files'] = files;
    data['payload_files'] = payloadFiles;
    return data;
  }
}
