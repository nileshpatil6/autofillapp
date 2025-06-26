class FieldMapping {
  final String key;
  String value;

  FieldMapping({required this.key, required this.value});
}

class MappingModel {
  List<FieldMapping> fields;
  bool autoSubmit;

  MappingModel({required this.fields, this.autoSubmit = false});

  Map<String, dynamic> toJson() => {
    for (var f in fields) f.key: f.value,
    '__autoSubmit': autoSubmit,
  };

  static MappingModel fromJson(Map<String, dynamic> json) {
    // Use containsKey for safer check and provide default if not present or wrong type
    final auto = json.containsKey('__autoSubmit') && json['__autoSubmit'] is bool
                 ? json['__autoSubmit'] as bool
                 : false;

    // Create a mutable copy to avoid modifying the original map, then remove __autoSubmit
    final Map<String, dynamic> fieldsJson = Map.from(json);
    fieldsJson.remove('__autoSubmit');

    final fields = fieldsJson.keys
      .map((k) => FieldMapping(key: k, value: fieldsJson[k].toString()))
      .toList();
    return MappingModel(fields: fields, autoSubmit: auto);
  }
}
