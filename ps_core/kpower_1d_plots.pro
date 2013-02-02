

pro kpower_1d_plots, power_savefile, plot_weights = plot_weights, multi_pos = multi_pos, data_range = data_range, k_range = k_range, $
                     pub = pub, plotfile = plotfile, window_num = window_num, colors = colors, names = names, save_text = save_text, $
                     delta = delta, hinv = hinv

  if n_elements(window_num) eq 0 then window_num = 2

  nfiles = n_elements(power_savefile)
  if n_elements(names) gt 0 and n_elements(names) ne nfiles then message, 'Number of names does not match number of files'

  if n_elements(multi_pos) gt 0 then begin
     if n_elements(multi_pos) ne 4 then message, 'multi_pos must be a 4 element plot position vector'
     if max(multi_pos) gt 1 or min(multi_pos) lt 0 then message, 'multi_pos must be in normalized coordinates (between 0 & 1)'
     if multi_pos[2] le multi_pos[0] or multi_pos[3] le multi_pos[1] then $
        message, 'In multi_pos, x1 must be greater than x0 and y1 must be greater than y0 '

     no_erase = 1

     xlen = (multi_pos[2]-multi_pos[0])
     ylen = (multi_pos[3]-multi_pos[1])

     big_margin = [0.15, 0.2]      ;; in units of plot area (incl. margins)
     small_margin = [0.05, 0.1]    ;; in units of plot area (incl. margins)

     plot_pos = [big_margin[0], big_margin[1], (1-small_margin[0]), (1-small_margin[1])]

     new_pos = [xlen * plot_pos[0] + multi_pos[0], ylen * plot_pos[1] + multi_pos[1], $
                xlen * plot_pos[2] + multi_pos[0], ylen * plot_pos[3] + multi_pos[1]]

  endif else no_erase = 0

  if n_elements(plotfile) eq 0 then plotfile = strsplit(power_savefile[0], '.idlsave', /regex, /extract) + '_1dkplot.eps' $
  else if strcmp(strmid(plotfile, strlen(plotfile)-4), '.eps', /fold_case) eq 0 then plotfile = plotfile + '.eps'

  color_list = ['black', 'PBG5', 'red6', 'GRN3', 'PURPLE', 'ORANGE', 'TG2','TG8']
  
  if n_elements(colors) eq 0 then begin
     if nfiles gt n_elements(color_list) then colors = indgen(nfiles)*254/(nfiles-1) $
     else colors = color_list[indgen(nfiles)]
  endif     

  if keyword_set(save_text) then begin
     text_filename = strsplit(plotfile, '.eps', /regex, /extract) + '.txt'
     if nfiles gt 1 then if n_elements(names) ne 0 then text_labels = names else text_labels = strarr(nfiles)
        
     openw, lun, text_filename, /get_lun
  endif

  for i=0, nfiles-1 do begin
     restore, power_savefile[i]
     n_k = n_elements(power)

     if keyword_set(plot_weights) then begin
        if n_elements(weights) ne 0 then power = weights $
        else message, 'No weights array included in this file'
     endif
     
     if keyword_set(h_inv) then begin
        k_edges = k_edges / hubble_param
        if n_elements(k_centers) ne 0 then k_centers = k_centers / hubble_param
        if not keyword_set(weights) then power = power * (hubble_param)^3d
     endif

     log_bins = 1
     k_log_diffs = (alog10(k_edges) - shift(alog10(k_edges), 1))[2:*]
     if total(abs(k_log_diffs - k_log_diffs[0])) gt n_k*1e-15 then log_bins = 0

     if n_elements(k_centers) ne 0 then k_mid = k_centers $
     else if log_bins then k_mid = 10^(alog10(k_edges[1:*]) - k_bin/2.) else k_mid = k_edges[1:*] - k_bin/2.

     theory_delta = (power * k_mid^3d / (2d*!pi^2d)) ^(1/2d)

     if keyword_set(save_text) then begin
        if keyword_set(hinv) then printf, lun,  text_labels[i]+ ' k (h Mpc^-1)' $
        else printf, lun,  text_labels[i]+ ' k (Mpc^-1)'
        printf, lun, transpose(k_mid)
        printf, lun, ''
        if keyword_set(delta) then begin 
           printf, lun,  text_labels[i]+ ' delta (sqrt(k^3 Pk/(2pi^2)) -- mk)'
           printf, lun, transpose(theory_delta)
        endif else begin
           if keyword_set(hinv) then printf, lun, text_labels[i] + ' power (mk^2 h^-3 Mpc^3)' $
           else printf, lun,  text_labels[i]+ ' power (mk^2 Mpc^3)'
           printf, lun, transpose(power)
        endelse
        printf, lun, ''
     endif

     if keyword_set(delta) then power = theory_delta

     wh = where(power eq 0, count, complement = wh_good, ncomplement = count_good)
     if count_good eq 0 then message, 'No non-zero power'
     if count gt 0 then begin
        power = power[wh_good]
        k_mid = k_mid[wh_good]
     endif

     tag = 'f' + strsplit(string(i),/extract)
     if i eq 0 then begin
        power_plot = create_struct(tag, power)
        k_plot = create_struct(tag, k_mid)
  
        if n_elements(data_range) eq 0 then yrange = 10.^([floor(alog10(min(power))), ceil(alog10(max(power)))]) $
        else yrange = data_range
        if n_elements(k_range) eq 0 then begin
           if min(k_edges gt 0) then xrange = minmax(k_edges) else begin
              wh_gt0 = where(k_mid gt 0, count_gt0)
              if count_gt0 gt 0 then xrange = [min(k_mid[wh_gt0]), max(k_edges)] else stop
           endelse
        endif else xrange = k_range

     endif else begin
        if n_elements(data_range) eq 0 then yrange = minmax([yrange, 10.^([floor(alog10(min(power))), ceil(alog10(max(power)))])])
        if n_elements(k_range) eq 0 then begin
           if min(k_edges gt 0) then xrange_new = minmax(k_edges) else begin
              wh_gt0 = where(k_mid gt 0, count_gt0)
              if count_gt0 gt 0 then xrange_new = [min(k_mid[wh_gt0]), max(k_edges)] else stop
           endelse
           xrange = minmax([xrange, xrange_new])
        endif else xrange = k_range

        power_plot = create_struct(tag, power, power_plot)
        k_plot = create_struct(tag, k_mid, k_plot)
     endelse

     undefine, power
     if n_elements(k_edges) ne 0 then undefine, k_edges
     if n_elements(k_centers) ne 0 then undefine, k_centers
  endfor

  if keyword_set(save_text) then free_lun, lun

  tvlct, r, g, b, /get

  if keyword_set(pub) then begin
     charthick = 3
     thick = 3
     xthick = 3
     ythick = 3
     charsize = 2.5
     font = 1
     if nfiles gt 3 then legend_charsize = charsize / (nfiles/4.5d)  else legend_charsize = 2

    if n_elements(multi_pos) eq 0 then begin
       window, window_num
       pson, file = plotfile, /eps 
    endif
  endif else if n_elements(multi_pos) eq 0 then begin
     if windowavailable(window_num) then wset, window_num else window, window_num
  endif
  

  ;;plot, k_plot, power_plot, /ylog, /xlog, xrange = xrange, xstyle=1
  plot_order = sort(tag_names(power_plot))
  if keyword_set(delta) then ytitle = textoidl('(k^3 P_k /(2\pi^2))^{1/2} (mK)', font = font) $
  else begin
     if keyword_set(hinv) then ytitle = textoidl('P_k (mK^2 h^{-3} Mpc^3)', font = font) $
     else ytitle = textoidl('P_k (mK^2 Mpc^3)', font = font)
  endelse
  if keyword_set(hinv) then xtitle = textoidl('k (h Mpc^{-1})', font = font) $
  else xtitle = textoidl('k (Mpc^{-1})', font = font)

  cgplot, k_plot.(plot_order[0]), power_plot.(plot_order[0]), position = new_pos, /ylog, /xlog, xrange = xrange, yrange = yrange, $
          xstyle=1, ystyle=1, axiscolor = 'black', xtitle = xtitle, ytitle = ytitle, psym=10, xtickformat = 'exponent', $
          ytickformat = 'exponent', thick = thick, charthick = charthick, xthick = xthick, ythick = ythick, charsize = charsize, $
          font = font, noerase = no_erase
  for i=0, nfiles - 1 do cgplot, /overplot, k_plot.(plot_order[i]), power_plot.(plot_order[i]), psym=10, color = colors[i], $
                                 thick = thick

  if log_bins gt 0 then bottom = 1 else bottom = 0
  if n_elements(names) ne 0 then $
     al_legend, names, textcolor = colors, box = 0, /right, bottom = bottom, charsize = legend_charsize, charthick = charthick

  if keyword_set(pub) and n_elements(multi_pos) eq 0 then begin
     psoff
     wdelete, window_num
  endif
  
  tvlct, r, g, b
  

end
