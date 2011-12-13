# This is a partial copy of the famous jsProgressBarHandler of BRAMUS
# Is displays a progress bar filled at x%
# Author:    Thomas Gendulphe  (mailto:thomas.gendulphe@tgen.fr)
# Copyright:  Copyright (c) 2008
# License:   Distributes under creative commons Attribution-ShareAlike 2.5 license
module MyProgressBarHelper
  # Render a static image percentage bar with default parameters
  # * name used as an id for the progress bar
  # * value decimal value to represent (i.e. value <= 1)
  # * display_percentage_text set to true to display the value in a text form
  def static_progress_bar(name, value, display_percentage_text = false)
    value = ((value*100.0).round.to_f)/100.0
    result =  '<span id="'+name+'_progress_bar" >'+
            image_tag('progress_bar/percentImage.png',
              :style => 'margin: 0pt; padding: 0pt; width: 120px; height: 12px;
                          background-position: '+(value*120-120).to_s+'px 50%;
                          background-image: url(/images/progress_bar/percentImage_back.png);',
              :alt => (value*100).to_s+'%',
              :id => name+'_percentImage',
              :title => '80%')
     if display_percentage_text 
       result += '<span id="'+name+'_percentText">'+(value*100).to_s+'%'+'</span>'
     end
     result += '</span>'
  end
  
  # Adds necessary js file tags
  # Place this in the header of your layout (near other javascript_include_tag)
  def progress_bar_includes
    return '<!-- jsProgressBarHandler core -->'+javascript_include_tag("progress_bar/jsProgressBarHandler.js")
  end
end