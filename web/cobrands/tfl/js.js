(function(){

translation_strings.name.validName = 'Please enter your full name, Transport for London needs this information – if you do not wish your name to be shown on the site, untick the box below';
translation_strings.upload_default_message = 'Drag photo here to upload or <u>browse files</u>';

fixmystreet.tfl_link_update = function() {
    var lat = document.getElementById('fixmystreet.latitude');
    if (!lat) {
        return;
    }
    lat = lat.value;
    var lon = document.getElementById('fixmystreet.longitude').value;
    $('.js-not-tfl-link').each(function(){
        this.search = 'latitude=' + lat + '&longitude=' + lon;
    });
};
$(fixmystreet).on('maps:update_pin', fixmystreet.tfl_link_update);
$(fixmystreet).on('report_new:category_change', fixmystreet.tfl_link_update);

$(function() {
    function update_category_group_label() {
        var group = $("#report_inspect_form select#category option:selected").closest("optgroup").attr('label');
        var $label = $("#report_inspect_form select#category").closest("p").find("label");
        if (group) {
            $label.text("Category (" + group + ")");
        } else {
            $label.text("Category");
        }
    }
    $(document).on('change', "#report_inspect_form select#category", update_category_group_label);
    $(fixmystreet).on('display:report', update_category_group_label);
    update_category_group_label();
});

})();
