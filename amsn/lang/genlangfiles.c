#include <stdio.h>


#define MASTERFILE 	"langen"
#define LISTFILE	"../langlist"
#define LANGLISTDAT	"langlist.dat"

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


void checkMissingFor(char *langfile,char *langname,char *langcode,char *langenc) {
	FILE *f,*lf;
	int i,num;
	char keyname[MAXKEYLENGTH];
	char langfilename[255];
	
	sprintf(langfilename,"%s.dat",langfile);

	f=fopen(langfile,"r");
	lf=fopen(langfilename,"w");

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
		if (keytable[i]->missing==1) num++;
	}
	
	
	fprintf(lf,"%s %d %s %s\n",langenc,num,langcode,langname);
	for (i=0;i<keynum;i++) {
		if (keytable[i]->missing==1) {
		        fprintf(lf,"%s %s\n",keytable[i]->keyname,keytable[i]->translation);
			//printf("<a href=\"#key_%s\">%s</a><br>\n",keytable[i]->keyname,keytable[i]->keyname);
		}
	}


	fclose(f);
	fclose(lf);
}


void checkMissing() {
	FILE *f;
	char langfile[50];
	char langcode[10];
	char langenc[50];
	char langname[100];

	f=fopen(LISTFILE,"r");

	do {
		fscanf(f,"%s",langcode);
		fgetc(f);
		fscanf(f,"%s",langenc);
		fgetc(f);
		fgets(langname,100,f);

		if (feof(f)) break;

		langname[strlen(langname)-1]=0;

		sprintf(langfile,"lang%s",langcode);

		checkMissingFor(langfile,langname,langcode,langenc);

	} while(1);

	fclose(f);

}

void writeMasterKeys() {
 	FILE *f;
	int i;
	
	f=fopen("master.dat","w");

	for(i=0;i<keynum;i++) {
		fprintf(f,"%s %s\n",keytable[i]->keyname,keytable[i]->translation);

	}
	fclose(f);
}


void writeLangList() {
	FILE *f,*listfile;
	char langfile[50];
	char langcode[10];
	char langenc[50];
	char langname[100];
	int num;

	f=fopen(LISTFILE,"r");
	listfile=fopen(LANGLISTDAT,"w");

	do {
		fscanf(f,"%s",langcode);
		fgetc(f);
		fscanf(f,"%s",langenc);
		fgetc(f);
		fgets(langname,100,f);

		if (feof(f)) break;

		langname[strlen(langname)-1]=0;

		sprintf(langfile,"lang%s",langcode);
		num=countMissingFor(langfile);

		fprintf(listfile,"lang%s.dat %s %d %s\n",langcode,langenc,num,langname);

	} while(1);
	
	fclose(f);
	fclose(listfile);
}

int main () {

	readMaster();

	writeLangList();

	checkMissing();
	writeMasterKeys();

	return 0;
}
