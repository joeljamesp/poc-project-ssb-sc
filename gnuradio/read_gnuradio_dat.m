function x = read_gnuradio_dat(filepath)
    fid = fopen(filepath, 'rb');
    x = fread(fid, inf, 'float32');
    fclose(fid);
end
