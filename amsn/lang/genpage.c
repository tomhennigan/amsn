#include <stdio.h>


#define MASTERFILE 	"langen"
#define LISTFILE	"../langlist"

#define AMSN_VERSION	2
#define MAXKEYS	1024
#define MAXKEYLENGTH	50

typedef struct  {
	char keyname[MAXKEYLENGTH];
	char *translation;
	char missing;

} t_keytable;

t_keytable *keytable[MAXKEYS];
int keynum;

void readMaster() {
	FILE *f;
	char buffer[2048];
	char keyname[MAXKEYLENGTH];
	int ver;
	int i;


	f=fopen(MASTERFILE,"r");
	fscanf(f,"%s %d\n",buffer,&ver);


	if (strcmp("amsn_lang_version",buffer)) {
		printf ("Wrong language version file: ");
		printf (MASTERFILE);
		printf("\n");
		exit(-1);
	}

	keynum=0;

	do {

		fscanf (f,"%s",keyname);
		fgetc(f);
		fgets(buffer,2048,f);

		if (feof(f)) break;

		buffer[strlen(buffer)-1]=0;

		keytable[keynum]=(t_keytable*)malloc(sizeof(t_keytable));

		if (keytable[keynum]==NULL) {
			printf("Not enough memory for key table\n");
			exit(-1);
		}

		strcpy(keytable[keynum]->keyname,keyname);

		keytable[keynum]->translation=(char*)malloc(strlen(buffer)+1);
		strcpy(keytable[keynum]->translation,buffer);


		keynum++;
	} while(1);

	fclose(f);


}


int countMissingFor(char *langfile) {
	FILE *f;
	int i,num;
	char keyname[MAXKEYLENGTH];

	f=fopen(langfile,"r");

	for (i=0;i<keynum;i++) {
		keytable[i]->missing=1;
	}


	do {
		fscanf(f,"%s",keyname);
		while (fgetc(f)!='\n') if (feof(f)) break;
		if(feof(f)) break;

		for (i=0;i<keynum;i++) {
			if (!strcmp(keytable[i]->keyname,keyname)) {
				keytable[i]->missing=0;
				break;
			}
		}

	} while(1);

	num=0;
	for (i=0;i<keynum;i++) {
		if (keytable[i]->missing==1) {
			num++;
		}
	}

	fclose(f);
	
	return num;
}


void checkMissingFor(char *langfile,char *langname) {
	FILE *f;
	int i,num;
	char keyname[MAXKEYLENGTH];

	f=fopen(langfile,"r");

	for (i=0;i<keynum;i++) {
		keytable[i]->missing=1;
	}


	do {
		fscanf(f,"%s",keyname);
		while (fgetc(f)!='\n') if (feof(f)) break;
		if(feof(f)) break;

		for (i=0;i<keynum;i++) {
			if (!strcmp(keytable[i]->keyname,keyname)) {
				keytable[i]->missing=0;
				break;
			}
		}

	} while(1);

	num=0;
	for (i=0;i<keynum;i++) {
		if (keytable[i]->missing==1) {
			printf("<a href=\"#key_%s\">%s</a><br>\n",keytable[i]->keyname,keytable[i]->keyname);
			num++;
		}
	}

	if (num==0) {
		printf("<i>Not missing any sentences</i><br>\n",keytable[i]->keyname);
	}

	printf("<br>");


	fclose(f);
}


void checkMissing() {
	FILE *f;
	char langfile[50];
	char langcode[10];
	char langname[100];

	f=fopen(LISTFILE,"r");

	do {
		fscanf(f,"%s",langcode);
		fgetc(f);
		fgets(langname,100,f);

		if (feof(f)) break;

		langname[strlen(langname)-1]=0;

		sprintf(langfile,"lang%s",langcode);

		if (strcmp(langfile,MASTERFILE)) {

		  printf("<ul><li><b><a name=\"%s\"></a>%s (%s)</b></li></ul>\n",langcode,langname,langcode);
		  checkMissingFor(langfile,langname);
		}

	} while(1);

	fclose(f);

}

void writeMasterKeys() {
	int i;

	printf("<center><big><big><b><a name=\"en\">English translations</a></b></big></big></center><br>\n");

	printf("<table border=0 valign=top>\n");

	for(i=0;i<keynum;i++) {
		printf("<tr><td><a name=\"key_%s\"></a><b>%s</b></td><td> %s<br></td></tr>\n",keytable[i]->keyname,keytable[i]->keyname,keytable[i]->translation);

	}
	
	printf("</table>\n");
}

void writeFile(const char *name) {
	
	FILE *f;
	char c;
	
	f=fopen(name,"r");
	do {
		c=fgetc(f);
		if (feof(f)) break;
		printf("%c",c);
	} while(1);

}


void writeLocalLinks() {
	FILE *f;
	char langfile[50];
	char langcode[10];
	char langname[100];
	int num;

	f=fopen(LISTFILE,"r");

	printf("<table border=0 cellpadding=5>\n");

	printf("<tr><td><b><font size=-2>See missing for:</font></b></td><td><b><font size=-2>#</font></b></td><td><b><font size=-2>D/L</font></b></td></tr>\n");

	do {
		fscanf(f,"%s",langcode);
		fgetc(f);
		fgets(langname,100,f);

		if (feof(f)) break;

		langname[strlen(langname)-1]=0;

		sprintf(langfile,"lang%s",langcode);
		num=countMissingFor(langfile);

		  printf("<tr><td><font size=-2><a href=\"#%s\">%s</a></font></td><td>%d</td><td><a href=\"http://cvs.sourceforge.net/cgi-bin/viewcvs.cgi/*checkout*/amsn/msn/lang/lang%s?rev=HEAD&amp;content-type=text/plain\">%s</a></td></tr>\n",langcode,langname,num,langcode,langcode);

	} while(1);
	
	printf("</table>\n");

	fclose(f);
}

int main () {

	readMaster();

	writeFile("lang1.tmpl");
	writeLocalLinks();
	writeFile("lang2.tmpl");

	checkMissing();
	writeMasterKeys();

	writeFile("lang3.tmpl");

	return 0;
}
