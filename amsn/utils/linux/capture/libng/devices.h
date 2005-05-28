
struct ng_device_config {
    char *video;
    char *radio;
    char *vbi;
    char *dsp;
    char *mixer;
    char *video_scan[32];
    char *vbi_scan[32];
    char *mixer_scan[32];
    char *dsp_scan[32];
};
extern struct ng_device_config ng_dev;
