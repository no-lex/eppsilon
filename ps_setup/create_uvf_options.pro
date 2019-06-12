function create_uvf_options, uvf_options = uvf_options, $
    delta_uv_lambda = delta_uv_lambda, max_uv_lambda = max_uv_lambda, $
    full_image = full_image, uv_avg = uv_avg, uv_img_clip = uv_img_clip, $
    require_radec = require_radec, dft_fchunk = dft_fchunk, $
    no_dft_progress = no_dft_progress, return_new = return_new

  if keyword_set(full_image) and n_elements(delta_uv_lambda) gt 0 then begin
    message, 'full_image and delta_uv_lambda cannot both be set'
  endif

  update_tags = list()
  update_values = list()
  if n_elements(uvf_options) eq 0 then begin
    ;; default to giving dft progress reports
    if n_elements(no_dft_progress) eq 0 then no_dft_progress = 0

    ;; default to not using full images
    if n_elements(full_image) eq 0 then full_image = 0

    ;; default to not requiring radec
    if n_elements(require_radec) eq 0 then require_radec = 0

    uvf_options = {no_dft_progress: no_dft_progress, full_image: full_image, $
                   require_radec: require_radec}
  endif else begin
    if n_elements(no_dft_progress) gt 0 then begin
      update_tags.add, 'no_dft_progress'
      update_values.add, no_dft_progress
    endif

    if n_elements(full_image) gt 0 then begin
      update_tags.add, 'full_image'
      update_values.add, full_image
    endif
  endelse

  if n_elements(delta_uv_lambda) gt 0 then begin
    update_tags.add, 'delta_uv_lambda'
    update_values.add, delta_uv_lambda
  endif
  if n_elements(max_uv_lambda) gt 0 then begin
    update_tags.add, 'max_uv_lambda'
    update_values.add, max_uv_lambda
  endif

  if n_elements(uv_avg) gt 0 then begin
    update_tags.add, 'uv_avg'
    update_values.add, uv_avg
  endif
  if n_elements(uv_img_clip) gt 0 then begin
    update_tags.add, 'uv_img_clip'
    update_values.add, uv_img_clip
  endif

  if n_elements(dft_fchunk) gt 0 then begin
    update_tags.add, 'dft_fchunk'
    update_values.add, dft_fchunk
  endif

  if n_elements(update_tags) gt 0 or keyword_set(return_new) then begin
    update_tags = update_tags.toarray()

    new_uvf_options = update_option_struct(uvf_options, update_tags, update_values, $
      return_new = return_new)

      return, new_uvf_options
  endif else begin
    return, uvf_options
  endelse
end
