#include <stdio.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#if ((FREETYPE_MAJOR < 2) || ((FREETYPE_MINOR == 0) && (FREETYPE_PATCH < 9)))
#error "Need FreeType 2.0.9 or newer"
#endif
int main(void) {
    FT_Library library;
    FT_Init_FreeType(&library);
    return 0;
}
