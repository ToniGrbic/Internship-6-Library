PGDMP         -                {            DUMP_dz_Library    14.2    14.2 I    J           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            K           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            L           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            M           1262    41417    DUMP_dz_Library    DATABASE     u   CREATE DATABASE "DUMP_dz_Library" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'English_United States.1252';
 !   DROP DATABASE "DUMP_dz_Library";
                postgres    false            �            1255    41568    borrowbook(integer, integer) 	   PROCEDURE       CREATE PROCEDURE public.borrowbook(IN book_id integer, IN user_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    loan_date DATE := CURRENT_DATE;
    return_date DATE := loan_date + INTERVAL '20 days';
BEGIN
    CASE
        WHEN NOT EXISTS (SELECT * FROM Books WHERE BookID = book_id) THEN
            RAISE EXCEPTION 'Specified book does not exist';
        WHEN NOT EXISTS (SELECT * FROM Users WHERE UserID = user_id) THEN
            RAISE EXCEPTION 'Specified user does not exist';
        WHEN EXISTS (SELECT * FROM BookLoans WHERE BookID = book_id AND IsReturned = false) THEN
            RAISE EXCEPTION 'Book is already borrowed';
        WHEN (SELECT COUNT(*) FROM BookLoans WHERE UserID = user_id AND IsReturned = false) >= 3 THEN
            RAISE EXCEPTION 'User has already borrowed 3 books';
        ELSE
            INSERT INTO BookLoans (LoanDate, ReturnDate, BookID, UserID, IsExtendedLoan, IsReturned, CostOfFine)
            VALUES (loan_date, return_date, book_id, user_id, false, false, 0);
    END CASE;
END;
$$;
 J   DROP PROCEDURE public.borrowbook(IN book_id integer, IN user_id integer);
       public          postgres    false            �            1255    41569 %   checkloanexpiryandupdatefine(integer) 	   PROCEDURE     �  CREATE PROCEDURE public.checkloanexpiryandupdatefine(IN book_loan_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    book_id INT;
    return_date DATE;
    current_date DATE := CURRENT_DATE;
    genre VARCHAR(50);
    fine INT := 0;
    days INT;
BEGIN
    SELECT BookID, ReturnDate, Genre INTO book_id, return_date, genre FROM BookLoans WHERE BookLoanID = book_loan_id;

    IF return_date >= current_date THEN
        RETURN;
    END IF;

    days := current_date - return_date;

    FOR i IN 1..days LOOP
        IF EXTRACT(MONTH FROM return_date + i) BETWEEN 6 AND 9 THEN --ljeto
            IF EXTRACT(DOW FROM return_date + i) BETWEEN 1 AND 5 THEN 
                fine := fine + 30; --radni dani
            ELSE
                fine := fine + 20; --vikend
            END IF;
        ELSE -- ostatak godine
            IF genre = 'lektira' THEN
                fine := fine + 50;
            ELSE
                IF EXTRACT(DOW FROM return_date + i) BETWEEN 1 AND 5 THEN
                    fine := fine + 40; -- radni dani
                ELSE
                    fine := fine + 20; -- vikend
                END IF;
            END IF;
        END IF;
    END LOOP;

    UPDATE BookLoans SET CostOfFine = fine WHERE BookLoanID = book_loan_id;
END;
$$;
 M   DROP PROCEDURE public.checkloanexpiryandupdatefine(IN book_loan_id integer);
       public          postgres    false            �            1259    41467    authors    TABLE     �  CREATE TABLE public.authors (
    authorid integer NOT NULL,
    firstname character varying(50) NOT NULL,
    lastname character varying(50) NOT NULL,
    dateofbirth date NOT NULL,
    isalive boolean NOT NULL,
    gender character varying(50) NOT NULL,
    countryid integer,
    CONSTRAINT chk_gender CHECK (((gender)::text = ANY ((ARRAY['MUŠKO'::character varying, 'ŽENSKO'::character varying, 'NEPOZNATO'::character varying, 'OSTALO'::character varying])::text[])))
);
    DROP TABLE public.authors;
       public         heap    postgres    false            �            1259    41466    authors_authorid_seq    SEQUENCE     �   CREATE SEQUENCE public.authors_authorid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.authors_authorid_seq;
       public          postgres    false    216            N           0    0    authors_authorid_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.authors_authorid_seq OWNED BY public.authors.authorid;
          public          postgres    false    215            �            1259    41499    bookauthors    TABLE       CREATE TABLE public.bookauthors (
    authortype character varying(50) NOT NULL,
    bookid integer NOT NULL,
    authorid integer NOT NULL,
    CONSTRAINT chk_authortype CHECK (((authortype)::text = ANY ((ARRAY['glavni'::character varying, 'sporedni'::character varying])::text[])))
);
    DROP TABLE public.bookauthors;
       public         heap    postgres    false            �            1259    41523 	   bookloans    TABLE     O  CREATE TABLE public.bookloans (
    bookloanid integer NOT NULL,
    loandate date NOT NULL,
    returndate date NOT NULL,
    bookid integer,
    userid integer,
    isextendedloan boolean NOT NULL,
    isreturned boolean NOT NULL,
    costoffine real NOT NULL,
    CONSTRAINT chk_loan_return_date CHECK ((returndate >= loandate))
);
    DROP TABLE public.bookloans;
       public         heap    postgres    false            �            1259    41522    bookloans_bookloanid_seq    SEQUENCE     �   CREATE SEQUENCE public.bookloans_bookloanid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.bookloans_bookloanid_seq;
       public          postgres    false    223            O           0    0    bookloans_bookloanid_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.bookloans_bookloanid_seq OWNED BY public.bookloans.bookloanid;
          public          postgres    false    222            �            1259    41487    books    TABLE     �  CREATE TABLE public.books (
    bookid integer NOT NULL,
    genre character varying(50) NOT NULL,
    isbn character varying(50) NOT NULL,
    libraryid integer NOT NULL,
    publishdate date NOT NULL,
    title character varying(120) NOT NULL,
    CONSTRAINT chk_genre CHECK (((genre)::text = ANY ((ARRAY['lektira'::character varying, 'umjetnička'::character varying, 'znanstvena'::character varying, 'biografija'::character varying, 'stručna'::character varying])::text[])))
);
    DROP TABLE public.books;
       public         heap    postgres    false            �            1259    41486    books_bookid_seq    SEQUENCE     �   CREATE SEQUENCE public.books_bookid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.books_bookid_seq;
       public          postgres    false    218            P           0    0    books_bookid_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.books_bookid_seq OWNED BY public.books.bookid;
          public          postgres    false    217            �            1259    41460 	   countries    TABLE     �   CREATE TABLE public.countries (
    countryid integer NOT NULL,
    countryname character varying(50) NOT NULL,
    population integer NOT NULL,
    averagesalary integer NOT NULL
);
    DROP TABLE public.countries;
       public         heap    postgres    false            �            1259    41459    countries_countryid_seq    SEQUENCE     �   CREATE SEQUENCE public.countries_countryid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.countries_countryid_seq;
       public          postgres    false    214            Q           0    0    countries_countryid_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.countries_countryid_seq OWNED BY public.countries.countryid;
          public          postgres    false    213            �            1259    41550 
   librarians    TABLE     �   CREATE TABLE public.librarians (
    librarianid integer NOT NULL,
    firstname character varying(50) NOT NULL,
    lastname character varying(50) NOT NULL,
    libraryid integer
);
    DROP TABLE public.librarians;
       public         heap    postgres    false            �            1259    41549    librarians_librarianid_seq    SEQUENCE     �   CREATE SEQUENCE public.librarians_librarianid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.librarians_librarianid_seq;
       public          postgres    false    225            R           0    0    librarians_librarianid_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.librarians_librarianid_seq OWNED BY public.librarians.librarianid;
          public          postgres    false    224            �            1259    41433 	   libraries    TABLE     r   CREATE TABLE public.libraries (
    libraryid integer NOT NULL,
    libraryname character varying(50) NOT NULL
);
    DROP TABLE public.libraries;
       public         heap    postgres    false            �            1259    41432    libraries_libraryid_seq    SEQUENCE     �   CREATE SEQUENCE public.libraries_libraryid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.libraries_libraryid_seq;
       public          postgres    false    212            S           0    0    libraries_libraryid_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.libraries_libraryid_seq OWNED BY public.libraries.libraryid;
          public          postgres    false    211            �            1259    41516    users    TABLE     �   CREATE TABLE public.users (
    userid integer NOT NULL,
    firstname character varying(50) NOT NULL,
    lastname character varying(50) NOT NULL
);
    DROP TABLE public.users;
       public         heap    postgres    false            �            1259    41515    users_userid_seq    SEQUENCE     �   CREATE SEQUENCE public.users_userid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.users_userid_seq;
       public          postgres    false    221            T           0    0    users_userid_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.users_userid_seq OWNED BY public.users.userid;
          public          postgres    false    220            �            1259    41426    workinghours    TABLE     ,  CREATE TABLE public.workinghours (
    workinghoursid integer NOT NULL,
    dayofweek integer NOT NULL,
    opentime time without time zone NOT NULL,
    closetime time without time zone NOT NULL,
    libraryid integer,
    CONSTRAINT chk_dayofweek CHECK (((dayofweek >= 1) AND (dayofweek <= 7)))
);
     DROP TABLE public.workinghours;
       public         heap    postgres    false            �            1259    41425    workinghours_workinghoursid_seq    SEQUENCE     �   CREATE SEQUENCE public.workinghours_workinghoursid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 6   DROP SEQUENCE public.workinghours_workinghoursid_seq;
       public          postgres    false    210            U           0    0    workinghours_workinghoursid_seq    SEQUENCE OWNED BY     c   ALTER SEQUENCE public.workinghours_workinghoursid_seq OWNED BY public.workinghours.workinghoursid;
          public          postgres    false    209            �           2604    41470    authors authorid    DEFAULT     t   ALTER TABLE ONLY public.authors ALTER COLUMN authorid SET DEFAULT nextval('public.authors_authorid_seq'::regclass);
 ?   ALTER TABLE public.authors ALTER COLUMN authorid DROP DEFAULT;
       public          postgres    false    215    216    216            �           2604    41526    bookloans bookloanid    DEFAULT     |   ALTER TABLE ONLY public.bookloans ALTER COLUMN bookloanid SET DEFAULT nextval('public.bookloans_bookloanid_seq'::regclass);
 C   ALTER TABLE public.bookloans ALTER COLUMN bookloanid DROP DEFAULT;
       public          postgres    false    222    223    223            �           2604    41490    books bookid    DEFAULT     l   ALTER TABLE ONLY public.books ALTER COLUMN bookid SET DEFAULT nextval('public.books_bookid_seq'::regclass);
 ;   ALTER TABLE public.books ALTER COLUMN bookid DROP DEFAULT;
       public          postgres    false    217    218    218            �           2604    41463    countries countryid    DEFAULT     z   ALTER TABLE ONLY public.countries ALTER COLUMN countryid SET DEFAULT nextval('public.countries_countryid_seq'::regclass);
 B   ALTER TABLE public.countries ALTER COLUMN countryid DROP DEFAULT;
       public          postgres    false    213    214    214            �           2604    41553    librarians librarianid    DEFAULT     �   ALTER TABLE ONLY public.librarians ALTER COLUMN librarianid SET DEFAULT nextval('public.librarians_librarianid_seq'::regclass);
 E   ALTER TABLE public.librarians ALTER COLUMN librarianid DROP DEFAULT;
       public          postgres    false    224    225    225            �           2604    41436    libraries libraryid    DEFAULT     z   ALTER TABLE ONLY public.libraries ALTER COLUMN libraryid SET DEFAULT nextval('public.libraries_libraryid_seq'::regclass);
 B   ALTER TABLE public.libraries ALTER COLUMN libraryid DROP DEFAULT;
       public          postgres    false    212    211    212            �           2604    41519    users userid    DEFAULT     l   ALTER TABLE ONLY public.users ALTER COLUMN userid SET DEFAULT nextval('public.users_userid_seq'::regclass);
 ;   ALTER TABLE public.users ALTER COLUMN userid DROP DEFAULT;
       public          postgres    false    221    220    221            �           2604    41429    workinghours workinghoursid    DEFAULT     �   ALTER TABLE ONLY public.workinghours ALTER COLUMN workinghoursid SET DEFAULT nextval('public.workinghours_workinghoursid_seq'::regclass);
 J   ALTER TABLE public.workinghours ALTER COLUMN workinghoursid DROP DEFAULT;
       public          postgres    false    210    209    210            >          0    41467    authors 
   TABLE DATA           i   COPY public.authors (authorid, firstname, lastname, dateofbirth, isalive, gender, countryid) FROM stdin;
    public          postgres    false    216   ka       A          0    41499    bookauthors 
   TABLE DATA           C   COPY public.bookauthors (authortype, bookid, authorid) FROM stdin;
    public          postgres    false    219   ��       E          0    41523 	   bookloans 
   TABLE DATA           }   COPY public.bookloans (bookloanid, loandate, returndate, bookid, userid, isextendedloan, isreturned, costoffine) FROM stdin;
    public          postgres    false    223   ��       @          0    41487    books 
   TABLE DATA           S   COPY public.books (bookid, genre, isbn, libraryid, publishdate, title) FROM stdin;
    public          postgres    false    218   ռ       <          0    41460 	   countries 
   TABLE DATA           V   COPY public.countries (countryid, countryname, population, averagesalary) FROM stdin;
    public          postgres    false    214   (      G          0    41550 
   librarians 
   TABLE DATA           Q   COPY public.librarians (librarianid, firstname, lastname, libraryid) FROM stdin;
    public          postgres    false    225   /7      :          0    41433 	   libraries 
   TABLE DATA           ;   COPY public.libraries (libraryid, libraryname) FROM stdin;
    public          postgres    false    212   �O      C          0    41516    users 
   TABLE DATA           <   COPY public.users (userid, firstname, lastname) FROM stdin;
    public          postgres    false    221   �R      8          0    41426    workinghours 
   TABLE DATA           a   COPY public.workinghours (workinghoursid, dayofweek, opentime, closetime, libraryid) FROM stdin;
    public          postgres    false    210   �|      V           0    0    authors_authorid_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.authors_authorid_seq', 1, false);
          public          postgres    false    215            W           0    0    bookloans_bookloanid_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.bookloans_bookloanid_seq', 3, true);
          public          postgres    false    222            X           0    0    books_bookid_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.books_bookid_seq', 1, false);
          public          postgres    false    217            Y           0    0    countries_countryid_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.countries_countryid_seq', 1, false);
          public          postgres    false    213            Z           0    0    librarians_librarianid_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.librarians_librarianid_seq', 1, false);
          public          postgres    false    224            [           0    0    libraries_libraryid_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.libraries_libraryid_seq', 1, false);
          public          postgres    false    211            \           0    0    users_userid_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.users_userid_seq', 1, false);
          public          postgres    false    220            ]           0    0    workinghours_workinghoursid_seq    SEQUENCE SET     N   SELECT pg_catalog.setval('public.workinghours_workinghoursid_seq', 1, false);
          public          postgres    false    209            �           2606    41472    authors authors_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.authors
    ADD CONSTRAINT authors_pkey PRIMARY KEY (authorid);
 >   ALTER TABLE ONLY public.authors DROP CONSTRAINT authors_pkey;
       public            postgres    false    216            �           2606    41503    bookauthors bookauthors_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.bookauthors
    ADD CONSTRAINT bookauthors_pkey PRIMARY KEY (bookid, authorid);
 F   ALTER TABLE ONLY public.bookauthors DROP CONSTRAINT bookauthors_pkey;
       public            postgres    false    219    219            �           2606    41528    bookloans bookloans_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.bookloans
    ADD CONSTRAINT bookloans_pkey PRIMARY KEY (bookloanid);
 B   ALTER TABLE ONLY public.bookloans DROP CONSTRAINT bookloans_pkey;
       public            postgres    false    223            �           2606    41492    books books_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_pkey PRIMARY KEY (bookid);
 :   ALTER TABLE ONLY public.books DROP CONSTRAINT books_pkey;
       public            postgres    false    218            �           2606    41465    countries countries_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (countryid);
 B   ALTER TABLE ONLY public.countries DROP CONSTRAINT countries_pkey;
       public            postgres    false    214            �           2606    41555    librarians librarians_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY public.librarians
    ADD CONSTRAINT librarians_pkey PRIMARY KEY (librarianid);
 D   ALTER TABLE ONLY public.librarians DROP CONSTRAINT librarians_pkey;
       public            postgres    false    225            �           2606    41438    libraries libraries_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.libraries
    ADD CONSTRAINT libraries_pkey PRIMARY KEY (libraryid);
 B   ALTER TABLE ONLY public.libraries DROP CONSTRAINT libraries_pkey;
       public            postgres    false    212            �           2606    41521    users users_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (userid);
 :   ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
       public            postgres    false    221            �           2606    41431    workinghours workinghours_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.workinghours
    ADD CONSTRAINT workinghours_pkey PRIMARY KEY (workinghoursid);
 H   ALTER TABLE ONLY public.workinghours DROP CONSTRAINT workinghours_pkey;
       public            postgres    false    210            �           2606    41473    authors authors_countryid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.authors
    ADD CONSTRAINT authors_countryid_fkey FOREIGN KEY (countryid) REFERENCES public.countries(countryid);
 H   ALTER TABLE ONLY public.authors DROP CONSTRAINT authors_countryid_fkey;
       public          postgres    false    216    214    3223            �           2606    41509 %   bookauthors bookauthors_authorid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.bookauthors
    ADD CONSTRAINT bookauthors_authorid_fkey FOREIGN KEY (authorid) REFERENCES public.authors(authorid);
 O   ALTER TABLE ONLY public.bookauthors DROP CONSTRAINT bookauthors_authorid_fkey;
       public          postgres    false    219    216    3225            �           2606    41504 #   bookauthors bookauthors_bookid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.bookauthors
    ADD CONSTRAINT bookauthors_bookid_fkey FOREIGN KEY (bookid) REFERENCES public.books(bookid);
 M   ALTER TABLE ONLY public.bookauthors DROP CONSTRAINT bookauthors_bookid_fkey;
       public          postgres    false    3227    219    218            �           2606    41529    bookloans bookloans_bookid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.bookloans
    ADD CONSTRAINT bookloans_bookid_fkey FOREIGN KEY (bookid) REFERENCES public.books(bookid);
 I   ALTER TABLE ONLY public.bookloans DROP CONSTRAINT bookloans_bookid_fkey;
       public          postgres    false    3227    218    223            �           2606    41534    bookloans bookloans_userid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.bookloans
    ADD CONSTRAINT bookloans_userid_fkey FOREIGN KEY (userid) REFERENCES public.users(userid);
 I   ALTER TABLE ONLY public.bookloans DROP CONSTRAINT bookloans_userid_fkey;
       public          postgres    false    3231    223    221            �           2606    41493    books books_libraryid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_libraryid_fkey FOREIGN KEY (libraryid) REFERENCES public.libraries(libraryid);
 D   ALTER TABLE ONLY public.books DROP CONSTRAINT books_libraryid_fkey;
       public          postgres    false    212    218    3221            �           2606    41556 $   librarians librarians_libraryid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.librarians
    ADD CONSTRAINT librarians_libraryid_fkey FOREIGN KEY (libraryid) REFERENCES public.libraries(libraryid);
 N   ALTER TABLE ONLY public.librarians DROP CONSTRAINT librarians_libraryid_fkey;
       public          postgres    false    225    3221    212            �           2606    41544 (   workinghours workinghours_libraryid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.workinghours
    ADD CONSTRAINT workinghours_libraryid_fkey FOREIGN KEY (libraryid) REFERENCES public.libraries(libraryid);
 R   ALTER TABLE ONLY public.workinghours DROP CONSTRAINT workinghours_libraryid_fkey;
       public          postgres    false    210    212    3221            >      x�m}�v�H��z�������g)ɶ�d���>�I�D��T��̋��{��7"f���>�uR �q#�FD�}������]�V'/(�w?��ϼg�������v����U��U����~��P7�F��~�{�yG����oO_�2J�"�S����֭���r�"k]�_�޷z_������ͦ^�4M�ۿ�)~~~d�]%�]ٶ'�^�*������o�qr�z?��lN�ƻ����{f|��o�ҫ̻�W+��[�o����A�{����?�W~:�ʽ�q}�>W}_W�����{X�iӲ,�*����~��JyX���r�a�U��9u������z�;�wnO`������X��WA�}�������ly4y���{oR,���͓�g����	�8�F�v�Ϫo����娃�Z��WA�}���n��nl���� �s�������Y����o�qg(S2_�S�����=��ۚR�U��O�,s�̼�<vX{וM�/䑡��yq��y��z��M�]7�Z^?�.��S�|�}�Mחޟ����'�(��s�������ʾ�yw}�p��׌[�֓3�
o��Yz�5Vñ���	$�Y�J�+��Mٷ��_�̪?ʃ����g�
sܷ��Z�G�C���������}� a�=A�T ���•�ۧ��<�X�<�][ɾ�x�B�f~rx��S�g}jJs�E�c���+h��8����L���Y�/_��ޕ���r5跫���u�1X��}�&y?Ɨ��Z�U)^���a]�j��Pz�Uy��f!�Ƒ�"��{�a���C�[����	%z�#u�Mw�J�/�~��Xq��7���������H�Ad�g_E�wW���Í�{�\y�6!���{:�$�F�㮯7[��b���+��8Q�}({�,�]�.�ȋ�;/N���x���O��p;�:(ʩ�#����B�,�f��ë�����P�T�;��j��Q�Ex���U�*�e����a,��Y�_Ł�y�V����:Q��|����#�����ձ�>t+��@�>�"��#���.[�K�7�&��|WK���qN}yZ���/Ѕ[�i��cFR<5�K]�*裾7�r��LOM��8��;n�vؕo��GgKq�������Ǫ\�8�j�f��^Źw����ޠ���ئ�2%9ްPu)��^�"���ޟ<�J|�z/��k�Z�D�P��o_���J�����c��̟�8�)���Jw;�P���x4g.�#�C#�$�w��p��å�>^6�c�k�06����o�]<6����4wc��D�s #�yKq3���޼��rPK��*�-{f�����r:�V`A,ˬ��x\��(�+���F�*��h~�(�J
�n�����ؚ�W����J}���{��x\�Vc/(�d	�'�>�W���\�����s}�4�2�>T��������	`^�%Zb�X0>s:�Q~��������~�b�Ječ<�Mv�&���/����nu+��c?alӔp�}��������g�z��_����r븱2�>6U��Cy�z� ﾥ���*���{�~�w�G} ����*��۷MY�[&�|�}�A\e8���]�Woh�n�Յܷ�هWY�]״-�]ۗb���6X+���W �w���V�	©�ݖ�:����k�U��7�tV��UF���[�Ky<�Ec`�'�A�B�^O|�ʼcNo}M�]� 񸱷�I~6)
-���U\�N��ӱ�ގ;�C�t=,1�
�׮�����Z!?���Y	1�}�E�7<���Ԭ�]`W95K���(U��u���y��������C�mKJ^���y6LL�s����ތ!T��u��Љe��SC��F��b��ye�+	��"����E��\g������a�̖�@$7���0�yF����طL� �x���s�B(��Dݩ�ji�r�j�{x�OG�\9�X%��)ɮ
_�Uw �]LG��������PX@�����NjǸ�F E(�~��U�r��$A��UX��k���K��_q�mbe턟�MYߖ}S����]<?��H�'�wP/�XD�̤W5^��~vr��\���ct�
�M������J���َ�DM�}�U�<��q���Y���R9se��<TT�U����C�J[J#��@P|%o �}���G����`�X���D���O���&Xz���<|YOŵ�x}[�s��t����ɵ�4e��6������p��&<ҫ��W/�9�J^c G1#Q*���Z�����=E�jp�|�g=`eƏ�֡*����4�)�:�~h ��Z������s�� 
��iU�N�������81�,@\�k5 5{�;��R
`�{�8�T��P��KSA�N�&*�2"�6|��Z����KUd�.��6}��z,_�Qb?��oX6�kUA`k�0�D�s������S�5U{w����$��Tq�_q?�AM��O���`qU����M}1*�z�2�8����*q5���Ή�XZг�H�m��IU��-@��W���l"�\Z�A� ǉ��Xq���^fjw�H����r!ٍU���G����/���K�����zcNb��g�q�b��������)���u߄�G���ɈT�i�V^+\4X��h����PWd"����������L#��D�a��(� ���kU��VD�����������F�V/U���� �/l�[z�J@��{9#n�(.Q��U� ��-`�6h�G��������7��;�*�*8��R��n���OS?'���"��Wz:������T�fe��%�����JlU�hͶU��A�����ޟ�+�}yؖ�GQ�H�Й�^?�Kݨ%�����:T��vWb���?kO}�(������{�k�k&6aE@� �%^{�+7+����.]m$Q�O�/�%AL?�Y�����yY
 ����r>��CJѓ����K�c���2�@H?��S=����ڄ�@X����{V��Ɵ|_"u:���~؜�F����!�6��[��?jQ-�B�3ǹ����^� �ł�������t�J0Ʊl���]����舵l,������(+�3"W�^Ა�pzic����"�+��K2R��N���ؘS��z
_3Μ�&�y�K����@%	����՛��ʾP<�$������E-�����}���}������>k�QSO&9N��JA4�N�1��bO:�ժ��mL�g�'ᩩ��������VD˷�T�[@���~��c�¯y,�ا8�����M��bO7���b�0�#f�x�>U�$�覇��3�ư��5�Y��z� ��B <� M��e�=�\=�J�m�HeZ���S`�#R;��>w��9��A��.�Έm�fpQ�^����R���֪9B�o7�hv�b4��,��Fk�{�̑c�fd�����{� ���J�w`�)����P�A%�iM�{7(�#�B�;0۞k�� �X�ב�o�9Y����G�⇲���s�|q]B�!�g1sb�j����u?+���4ղ����A��Y
m�o�e�y-�fo"F��	yw��o��"e�F���Z�z��� -��-b7� �E�U<����2'r!)/���8���-D�0Żc3Χ�M�F`���Lؕ��z���ޯr_�j�k�<b��x�\�Dy�9n��4�&����M��Ą0��7�ު�Q�o(ܲ<!�\�t��z0�H�6�La8rܳ�Pb�nˡ\��� �@���xs�L�m�'2���wW�h!��З+�]�u�$�WI��`Ց�[N}��f"����ȡ\�*\��X��0�HK{�x�"�
�a<��x4�b����ciH���ێ�����F����>��A�Jn��<���H�![�A^8��5��y�D$3	":7"Y$0�͉	�n�J���XB�#.R��;s��s9B)xs�'p�c�1�qa�zWL�#]���9΂7�X�0�'�l��    m���Q�I�����1W���M��Ec�f�r��X�`m�>=C��NӅ���A� �#��+��Q�I�X��s��T<^U`Ynr��d���'�.=�vݘ0>}�h����zځ>3{Gtyj̵��C�M�l�T80��B^��Q�řf��J�m�7
Ֆ)60�k\v8��ˮ���jcq}3�ޏ�K&��E��)老]�+�ؿW��cs��'��t^��Cyң�t"F\z������M� ���m�X�t~& v�ZM��02IS��B�B}��q�TǵF�"Y+\��qc�`�l$��L�P}��>1���>nG� g�1?��C|�/@oj�����\�o�aGh*�E�v؉,�z��]���pK�)ע�l6�ga���c�;V��IݚT�eWr'�V዗�ϒ	Y���d�"������Gi��1� XA���V��u
]FBƧ��#�@~v}_�	��nJ���x_p��]=�
O�uXaJC8O��� ��A�<���s���y{ ��p<tr�A!�XkH�%��i�~6��G��9�0x��;
Mձ�,������P}o�7�'9�<�ʱz16|�<��c-_U��4��=ħE�]�i#V�-'gV(>�S#��v�	`E��QN�9Jp�̘�l%���i�*�fw��C#(D�e�2���!��H��wW��n�A 7&�f3���"�H[�=4($����ca�5�򯝞��MT�:� �w��g`��@pћ4 `��拋�}�m������)`�
�M�s�B�̉��6Z��
������MGE�T���DL��Z�wf�Ø!)^��㊄���q��T�1c�=榦����.����Ɖ䂙��$B���|�|�3��p��uo��I�����\T� ��x�֞�|ٜq�����j���I�	��7���{\���4���1����p������2��([�am`�]տ��������[?��8�JnH��Nh��(ӯ�J8�-5	G��G��j�d�!�}�x/+���٣�O/�>��G}ԍ\��`����Q�OoS �1;v�3�2����J���S�J�K][Igܶ��:�����e��5����HH^��gyԨn��(�\���4:���qߍ'�;�%�)%�i�	O�-Ǎ��4Vj�h|ZbwW83������b����ș��ֶ�"�� ��ilr��K��ɧ;�Y��Pl!��0�Jj+�D��1X��t��B�pf��]D���0�!
�n�^͓@p���q����dߠ�N�eYF�h���Z&fZCڔ���]��	9� ���OL����L��g�B��z~�?ͤ��"�3A3z7qu3@�??�Sy!����Mv�T7�hq�ThM3�E*��J�b*�B�"�����
[ӑ�6��нa
�X��MkPf��j������1X/�5X�{��E�N�9�;�>d��Jx���42�9ژh&�ţ���= ݾ�+nX���5^��q��s��EĈ9�ay8�x�qS*�+v<}��<�@M�¯ӜG&�ny�\�K��w+.�ƄKS���-�w��?����8����3SZ�
����{S��f'����O�w�&`��E=P��u�B^�<����M]��WC:�:���(/�9MGv!��:��R�BY�տ�R���+����[�@Z
��uIP��D1�ش0z���E�D��l�wo��XL�"�Ll@[z1l
�5�+s�A��,bކ�X�[X0��)s�zBp���1�RB��bV���Đ�L�EO�c�$�T���*2FƢ�&.cb��ن_96=L\��s�	�	dPA^��(Y�R���v�"��ȇ:��HLG_�m�^*�.^Љb�O3u�1�}#�ҏ[�Z�`#��O)����W�g���qf��21�c��/����k'��,���mU _O�N�v�
I�����F j}o;�!$,/'Ͱ�L��P�a-⥧�W�!��y4o�p�$Fh8\t����9R��n��lH#��5���ZSR�|VQy��$rÉ��(�xʻX��s2��d��HC���DS���vzJ�w��K���°[�wSҬ(��	ᒑv�{	�g
F|Á�}� ��QJ;~V+!�b��Z�s��~y�F�{c��|��(z�;��a�7H����X�4�2.�V�Ux�?���u��V�����ai��\�4�0�1M�x��W�P����%���H����%/�+�w�(|�j⧼�c���� �l�m�6�L�����p�R�Q9nvW�J�h`��5�9\�̥���q#? 0�o�_d��Y�0�` )�A�y|Q?/
�!;�����ؓ���Ra��#�df���K"��n|���/eH�I��#�"_�0����T�����h#¡u��<$Î^$|�N���A���_�d�¸Ô����˰G� �ƍZ�py A����n�n�˞�-I��V'�Rӟ!�'��gnf;�o�-3G������<1��U&R��9稢(c�k7J�m�[��C]R}E9���ݛ��C߷[̇�2T�{��7[�ա2�В����>5̂oJ�~Q��2�M�ŁԻ�*@��M��%��/��W:��nϥi�����|�Ј-�0�kٗ2V�q�dlD,5k)c(f���޶�S�|V'�6f��ِ��F#�VR""��dp�3�i�]��9�h'�C)L��������P���=qk
.��m����c�B���圔)� �{�Cp�oc��S�.݆��	��+	�b؋eL���(Q�H����*,�@�I���'�o@@�gtfK+��*lpy7�|���^S#Aj
�\�^D�ߠ;B0�g��"����:��I�W��RY�n��(}���������O����wQ�1?�C�����(�][�.�Ͻ;R�n(�/]�(����Az���R��ꃪ�"�k�ϴO,M�y>�i<0��2;�Tw�0T���5Sz�D&&N7���Z�G�l�}t�!�sy�N�8�*�㠚)p��R�\��L�e��iW1�p���<_��"m���qaj��Q��ۉ�:��A��O�_�n:M��t� ��4�c�PWÅ³;�n;Cפa3�m�6I���Ǿհ�,N);����$����2���r��c%���7��) ���!Y��&g�*�<*f�4i�OQAB����#uU�{oNݻ5�\�㒗�����e"!����QBt_�2LU�8���e�d�z_�b�<6+���íL
w��f��H���#�EV~>�>�`�*�51����ϥS�U�Y��7\&7��KzԴd�<��c=�#'��r���H�M��{����0z��|ѝ6u�jJ�ty�u��x:>�S�oOj�#*�R�Ǥ=qa%?1E�6����:l9E��a?���������c{R�����
e%�Lf�f<��vo��3��s(��Ǧ4L}-�-"QWN�/)>,Ć�VG�I�X��vA���r���=� ����-��Ș�z힝)&�p�j�����M�wǯ�N2�Q�B��m"s�:�H������nue��/�93
w�cJS���	|���w}� k���0��(+�Lg
�.��T����oV�EE�3�u�$͢I��j� 'P�����t�Vֈ��,D\�>�(�P��ٞ�����H#,�f��ˁU�)]�e�ǌw����&�Z���(M�z�|��g��	��˓���)\����1�Ƿ����9F\�G�k>5ǉ��HN�I�;�U��C�X2B�]�����o���m_�'9�BCX� VA���c(�T�I�|f!�P`�_��t�,J��(�a��j*�n,�b�j5&�0��"b���T[������\?1��N�auH�2K�F���N���p���������Ûtz(D|	�e�:	!s+��\bJ�������2���|��]�l<����|�I��۾<    �܎5���|c)%���F��KP����{&����������
�~|�N�p�~���c��O@݀T�rUi��z,(41$�+$@�B�j��O��m|=d�o�	�޽J���d�e�P���{MD�?p=%����	�kct�VhF�I��7�r�/]ї&�sU�t��!�fRw�9Ӊx����n�/�Zq��!����A��k�`�!����y��ͺ�ۨ��M���@r���4��k�ܑ:��NH��ڽ�H�I��6��&@��!��7�ɰ@�a�f���(`�7=9^���oy_V}���S�sl��nb�Sm�]��s�R��z�a}0�]���{��G�_+¹E�$b��������T8U8Ax�qdHp��צy�)�s ^ȧ�@���/��@mqTxO��a!ҟ������ɥ��%)���f���L��1�q����./u7u]�]�qmh����d����,�H����m��Jr�Ih�B���o�7�O���fOC�G׮%�]��q��R[˙USz)X \�~���۝�kk�ж�)�+�s-��)��,<�6&q�]�>��&o��`��c���p_%�o\�(0T^[l���5�B�%/B�:��'�iI����݋y�t����༶��])�y٫H�2��?b�sZ�ϵR�L,Բ�[hU}�NR�� $�0�'	�y��DC�x:�^5���%�D*�(��y����l��dP�Z�kwZi�z�:f~(_�!�S�}������19��I��<�1ih��f��LX��'IB�C����Z��ƌu��������'���5��!�i��c̛���!J&�m�@��F�m�&g��ٽ�a�f�8����rAӘAY�G���V%���?M�^�&O2T���;�jqw$���Mm�f��K�M3������[9��;IÓ����~Q��}�<�-�hb~"Wh��(��	�8�	��	S�;����g���iΤ�x�����~Xi��;����g�\�Z�R@?�5�ƍ�2g1��\��X�,i2>�2Kȵ���	�l�'9�R��]+�[�ي�Z+G�,t8���+I!^��4����t/���--6l1��M��QI����1B��G�Q)��e�+�]iױe�:��Ǯ��k�'�|/$�E/ԸB��j-K*\��R&9W�G���ؗS��+��"G�@�0C�*��RZ)).w�5��T���|m�7#�yf���q� {vt���\�'�ˇ�S�Wv� �=w�X�#�w8'��$mNn��|׼Yp�c:5��!����2�0���Li�sfapZ�aE���8�EzQ���q��B֒j\�M��s�h�Ր��e�Ь�;��Nm���T��W�x�Mj6�l�S��2��`	{G�c'�|��/l6��޿�u��R+(48��piي�m�ؔ�x(ya�#��J)T��װ�\J�������C�6`B��؈!��]8���M���?w�z��E�0����~�Ȅ�M  ��W��v���Et;�y^����|���@�l�t�T�cc�$�bB�ME��L#��:yӘ�y$�Z=�|�8�>�Kc8��4B.�J��Y����Ϫ2is��җ�gTn�����	�#�3�ӹ�A�O�<�����t��'��W8*7���W�i��Ն)%�:S��[�A�>�w�i��$��'�۲��� s��|-�����0�^55K���)�s,�{��ϴϽ6��/�n)^�{��k������%LA;�� a���Z� �� 1'�pf�B@��������ӜHKѿ�
+�@B����UxH�긲;|9>�r�&�����y^h�j3�O}QJ�l9G~ٻ+�1h�Kͦo���#ENFg�e.P��Zvɿ��!~ 4�����.�H)Jv.>L�����I�;|����6�u���ƿ��H7��bME���v�x���'��{� �=�q/Ӛ���r�Q~��@�.s<��[y�_�#��ݔ���ۘE!�β��������{���
k�cj��t�̱"��Z,�zҖ7q4{�s\)��dR���x��n�jҩj��Ý�вx>��&�jk���>T��w�[1�b2t���m�jثy�Z�A�F�	�í���UWg�]t^J��C��)�X��֛*�\ZB�-�5�yߟM�4�MN�v���l����u��\�j��ph�=;K�*�4r��
B̤fK��C�-����� ��2ԡ���~�Hɂ13����[${��e	�m�
���:Y8�/6��錑�zb��>Z���l�"�w�v����u�a�"���st��M�cT�n�Z��Pt��P��XS�b�^)$ia:[+���� Cf�*���n_+A�K�?>���T��[����,'�Q��2�{m�f�d|V"]ݨ��Ifg&�Ď6�^BR���w�u�oSә��ϙ5�`
�K����P�����aY铰���B��iXV�"�tYk��MbiF��46�s�6���IyI��P1�Ȯ6AQ*��$)�ws�5;M�%�l	��SN���q�0$��+4p�k)e����JS�:���W�vB��u�J4
/����JR'�ZI�V�U�^bKҀ5��Jk�_�$�E���]g�л�8�c�5��i��F@�4��A��h��ܜo�����1,u?��E)�Ql�Z�D<MdG��ἥN7*M�)�w�����A�)��oiED��pY1AFh��Z*����sρ�5a좛�'|�u{�ǃ��EF����u`+��m�6zT���i$Y ��WV�/s�0��_/oC�q�9%�@��WB\���{�g�v�iq^H0�a�����*䧽)����&�D�cR���O��(7�J�j,�R������H����[p�����-9�W��䚕r9����w��=lנ ���PV��K��` bǾ�vdn�M�cͥo"�ή6H>Ֆ����1T�A��Ĺq��z�$Ms1�à��i�q%��+��+�o*%�k3�E0���V��q�$+�D�Ύ�?���=��IMM�-v1<5�5T3s�5�1WJ�.��1����2)�s)���֯���
ܖyҚ� ��C'Lu���
� U/�n����85�Te�L�&lDڐ�AR��Q�z{��"$����sv��W>#�Y��74 �L������i�h�W���Ad���Vsݚ��o	��I!A^�����b�t�<\6�a��`�06L씇e"�����]�O)P�kj�K������O���y�+��%04ĔT]����I}@v���qU����&FI�.��uה���Z����݂$e�b���Q�'�LKE+�c]D��@Vo�&.�� ٧�\��\��UW�A�RS<g��>�x��|7�uw���%+�����G��q�u��K����d
���4�����������5�wݸ1�|�u�(7�8�p���`:��|J�1pQJ�������RV]�ͭWgH�/ň\���f����0O�bi�~(��V����jN�)mo��4����$
�*i*�5������%� �c ��l"�_#�ꄄ��@�bTy���r�fgO�wj��\�-I���7�y�U�{��yʊ���s%��X��jQ73�60��J�n%B�L�lP�ee�����{M��~+S+L3["a��0ڄEK�9�`�<Ӑt��wf]��� �cqg���4r��p����w��1떆�T�r}��۲��N�3�҄>ގ}]�ִ��$g�����Qr�>�O;�L���>�fޗ��blX�����&�� �P���%.�+�ˮސZ)Xy� ��!��vDtGS��4�0�,��7Ӡ�^�r(���e��ġO��M�.4�+��?��c_M�}	Xv�F��l��{�����İm&ur$�k��^N �M'�'߅�"�)�S�؝b!)��&�� V�6{ob�;�&�]c�Wo���E��ϱ�m*+�@81�ko"�8Q������+5ǁ Q�o!`S� Ga}��4ј��GY픍:�Qp�X��B��m̘���!����ֱ�    ��i���<�r�8*�:���Ӟ�&82���b���Q���{)��s����'��謘)�4N�b�k�k�bj3d��|�Lˁ�tm��GD�>`i.]�o�+bh��p�N�W�ˎg�QIU~��e[r.{�v�g)�)X�me^
��#�a]�~��M�H&	��?�#��	��\v���I"/�����%�s�*��T�便W���$%1K�V��t0Y�UL��
�t$B�9I�ٴ�/f��F�I���}��"a:O�:������J���)�"Q����f׎��#/�Tz���~�{���� �M�3�TԌB��.pp�ԧ����8�@�j_6��vK��	� k:m53cƎ��iH?�Ԙ.4F	,H�>�/��/�e�g��iI��nJ�u�J��]Km,<�r?����n�%�����qx� P����tg���R\�ך>�Y_B�H�Vr��8eLfT`�i��]��2~W��vK�/�3c���oQҴ�����,(T�0����H�Cc����T��K~�1�SO��q4�j��.<�L+�H[ڜ�r���rY$���=��Z����[L��A+c?2��s�9Z"CU� �����:w	~9��J���Z��y\霨,���p�2ɂכ��b�zHA07����k�HlU�>*��H顎�	!ڤql:x|7�b띲ݕ�a�����gа=��*S7�̱�	4%	L�=���R�^���r8ѕ�b�m�Jrz9�|"4�'��SOM�szI�B�c[K�E�_Sd����k��]j���#�B�2y�/��9ϫ�ȆOol�>���Y�28`N]a���Ӭe~�"�y�̀�
���85s4�ܤ]�cU���UM�pT���f������Jg1�M������Q��bL�n?u���4B:�o\�Lѩc�����~z��,"<������-�h5�Fn�a��"��w�V���u�v�p����3�n*�Ŭ$�X���EK5�J�#����R�I>�,g?RL���DHi:b/F��*�t�����+��W�^�bբ�N��*[���Yd��!�#4�t�\��CF���7�AV��esm85\�P�v.�)�������`+�rS{_��r?d�hmąlmz��v4��t��{�+"�{X�W�a����O�WME�5qi�&�{���X3&��F+����	�.�VQlKr�$&���A�z��,�%��P�F��	ͩ���X�2O��ٍ�N)�y����ذ����U		ŁIÝ'�b�ح���mw0��ʍp�<0�.�_�T&���8|��pY�"�j�v�USCG�C�(�����>������<2��$~�����/���@E��'�Y��

`�k�s�)��?~{��0¹>��2V���
ڶd**�ø��_w�g������2��L�����_�JEF����,�I�H�����MQl���%�J��H{�UCV�3��r��0�D�\�q�WM�u�a��U+ݠh�ټj��,�e8ِ��fH�W-#�4��,*le�2x�l��lO�j��r΄/nZn��N�L~l�5VE:TE�.��O;U��Iւ:!���l� T盲�"o��� ��Gq�o����t� �Ή�Ų:�5Z�5U[\��4w;�^� �(���.Q�}V�'�컞:���q�-��������={����鲡&� �F1��!y_��v!iee\8���7�Z#L�P���r$�x*uȅ���/��h2���ҷ/�ڪʟ���ͽ�b���2�u�Z�;�;���PvA�\e����#c�$P�F��M��g�����<4'��ve#Aְ�p���4P����$4#+c�>91~��ܕ�3��C��fJl+�۝�
��E1�̏���aDD�gs[�Y��\Y�����s3�вG>,�zya!��7�-U	p!@�v7���t�M�kgP�0�9���bt;�5	a��xP78
��0�fj�Y��[���Q�jr ��@;^�g�<�Nf�Be��<7�+hiL��;닽3S��u�sb�9�tq�7����g��P��}��V��ҷ�,��m��MR�W�Ӏ��m%�m(�̕�oLu�E�s�e���~��R6²�{��a���N��s/涾��²�#H+�Q�j�l�s!��I��Zں�F \m�U�#��Z����ě+#��͙,R���]�9�␝leʒ
럥!%��sK�x��b��L�w����>}:7~EGT�j�����8
����%�ʜ�VD�j��1�4*��Ҩ��/8��2�ޕck*�n��3�2��3�TRΥ;'�D�b�G��g����B'6W3�X�L$\�0 3T%�����:��8G�f@Ǩ�bI
��d�.� N�AV{��N_~~�}����!�Sw>�]��I�ð��ѧ��v��ˤ���	�U=�h��;�g�����9��h�\)���<�"�U�lPe-���p*¼iT�MW�B��h�s�T�Խ7�E��ب<��V��:�p�A��i<����	N`)�(���Z���9��b&����mN1M%�3�/#w��N�V�}_W&�'�.k3( e�)o�״Q��s��F܏B����(�)Z�����,��~"#��'�̋;_�"�:׌�#UL32����.Bi[2�_i?���ʆd��˂�#k�ǩ�v��_��Rkl���<��7��N*+X�.A�'��zo)g��]+tR)+MIR�^�f�A��t!�JY�qw�l���7~V>�C�43�D���E��aae0�@���9+M���q�����Ͼ|��M�������)��p��fR�9$ ���M�į�Uq>�F���+� f�p�������dW�K{)~�;���^�U�hl1 *��i���Þu�8��a�'|n:���n�S��p8s`��yK��e��Y��.؉b��8���A�ͫ�f˝Aș�����l�9���M��\�Z�!�w�_gV�"G̑�1)vk��MSn�������q�>U���f�&������{�w2� }(��B�x�i���c6;���؍JnU�e��BO8���=�P�Sml�l��W��k�-r���w��t�O��>���"ᘦTD5%u���+'a�@�&�<$!Z�9�o�V�$�6�/9��ى������o��w�����W׼�ؿ�`�s��Y�sqȁ<����D^���6V������N�u{2\��u�;�����^zbi �=�,�8�ĐQ �p����.���&֦޿�}������M7�`�	��a�f�dmʹH��@M=�Lnj���nꋑ����+ǆO��!��d��ʔ��SYH��n���8�1��@"�%k��U[�E��� f	їW\Z�k!��i��<�4�T�,�}e��L%%!'̓�Wnw�4�-���Y��<J��M��/	�7Fp][��w��P�Xy�9ec���veJ��|5�2�Lb�һyD���3���X�s�͜Y���c��f��&�2u��eb[��G, >�z!nĹI	8���8�*���V����`��p1��tJƣA?��4v�Y�b�>Tfʡ�;,��Kc�J�J�?��jr�x�]ّ� :�;���VQ�1I���I S�����������ٗ�,��oʴϦ�[��^���$�h���nGa���T��}�f����S��J��H��Ӡ��%uR�%����H���ki�*�:����#�'��*�}�i�{�v���	���w�j��Vx/T���g\Ck�m�%��}�]+��guxi�� ���L�M�X�G�'�[��y.O/�������<r�9F7��N���	���۟q��aؙ��5$�$2E:NG�<)�eVy`��U-Ck�Fy�{�:�Z=��7tǙ�Ri2%d��R�I0w̜�S8�44�d�A��jq��朐�T�,{ʨ��T��G;�M��Ǝ�a���zee4�Sl�Q�l�=�!��t։��pӔ��6&��wg��($!�3O����­5�����!�,ͅ�ZeQ=�{�,�Φ�t���u7�&�e�A���3��3fqۘ�) .	  h�<�R�ҏ����@i�<���;9:I
"oN:�F�f�T�k�%�R�G��zc�>���w�ɚ�B��X~�h��bȣ�ƍw_���,�h���˳���J�M��`Y����mz-�=4Y|�z����L�,R!�侑��S�M�����<c�6}�<6�u\.FD����/"�/8z��ya��vAC�3Ѱ���KrӴ�ܨo��3y������^z�vdx�<R-PI�ד�w-���¸WyLXo�F�����&�� 5�C�HC�$G�+;�E�K��<��.$��Qp��, 𨡱^���Ņ���[�EzZ�	���@�bY~9`�i�9��0��n5!6��f��oﯲ5ý�J�I��-��s�p��vv��C��O�>�a\��T1�:��W������#Vn�ч�75l�FY-���& �~����!ř�N�U$޿���nNz�:$�ɽ�8�"5�[vi&��wR���"�;͖#?�U;��2�#�����(7*������S��͒��o��KuC�T^�� K~l#ͫh:���Vv&����"��//
��A�d�2,u������ΔB�B�J3��Gޟ�F�!<;rN^��YK�� CX\̩��@����������樄W���n�n�`biJ�͈#-�DXͧBY�CM�:��(�λÔ�����m=B�0�x�=I	�zg����X�X�R��W��g_\*\{���f�գ��<AK�xf�`��a�N� U���88�6N�[�*~�����16��G'��_�R}CJ��MJ��,O,�?��<Z��lř`��t���ǦJ�d�Y�,V�nCM�����Ȼv���U����BX`�J�Yl���(1�6W��	R g��i}�����g[�6A=�I�s��Pvm�A��0����9ϲZ��#�*�)ߛ�=�)��T��R�,s��ꭞ���pT¥�_ʕ��KZ��;�a�A���!���ؗos�Ɋ�b����zӸH;�9ܐ"$����?wf�����K�e�4єi��JKt�˾���S���!S�d05�s�~� �I���wo�p3/��o�7d�(���WM���܀a`�`�N��v�~�?,��p%��ݷ�5�k6@��rA�!��hE�������k��<�(�F&|9Hu_��9��ɺİq9�L����qX�Xʾ)cl˓R�(�*	�#s{�Q�-�n�:����n��*'�9A�!��v[σ��Xi�,L%Q��D]v.0R!4���J]Кc��������kؤ�3�v�����,&j�Σ+����P�M�W��8��\_-��<�]�w1����-���d_N�=����_+c���0���Dw�)�}=�<`���E�E�H��
��"u���Xa7$¸/�����Oe�;�v����zXYЯБ���Ri�N��H|���,Ǎ���d�:�q+����Yw�4<r;>l��&���B��Z�,)_�ɩU>3����UX:��:�k��[ׯ����{j��"I8��������@�^�Tt�f���=���j�n+P����(�-x��%�m ����xu �Q�nks~ɽ�ހ ��T�:������%�}WV�B:�P���>YQ$�Aʂt:�?���h��Y�9�1OC�(��w�Q>���|jY� �B��2��:�c�����ԟ�_�[J�ʼ�K�l䆃K�qwb�����!U�3�q�[��0��F�s����d4��mJK1N��Y?��I�*�ۓ�˙��lrp�����HƋ1���);j�Z�����u���LH�*����I?s�m}�R�jؐ��;�VlAJ��|����f������#"���4k��&�S��v�N���5\�E��%g��'\��)C��&��	V�ڥ��<+�s	]�'�e�fx�ln�y�l4(V%��"���Tڏ/&@�(YA�w꾓��<����l?�7T�]�}�y�nW�"'d�\���P�Y��i��:�N����_0cX;��;�R�yMM��Ũ^�j��g���J�MЙ��+��O��"V�Z 'A핧2[H>�����;��N;U�rC�ey������ʣs�c�j�@8��<_�A��xЂ<tc;ԓ�r᠌�h��?е�)�{۷��<�V&/���ZJ3�x��q��!��Y">��´p��"b�����z-�}r��ʔ [#D����i�~`L�e�pV�g�(�.��(�S�l�ls~>� =W��J��{,�D��Z��ɭ�<M4n.��H�����s |��&�T[�{k7�Ҕ�`��W�X؜�m0:+�A1��^�����_WWW�2��3      A      x�]�ݪ-1���y��'�⍠� *
>��-9S�{_�d&���T�O����������g��)����?�W�S�����~��6?���f���B��3�T+����ٿ�q���z������+���O	=���*ҏ�|5)U��*�B�5ʧ��,F���)Ƿ�y>�U�Y��3��W��yl}�N_{��J�n���7���i�����g��i��i2��X��l�Z�=>��g��i�_��t�"ʬ�5N�W�֞O;��'^��^B�����_u�>���̦1��k�U��*���h�Ug��u�{���@V�*S����^1Z���ݚ��f>�3^mz��j��c�_��W�-s�ǟ(%^�}f(�e��*3�3�)EO�ڬ��0ZȹR����}�8��ܻT|_$�\a�:�gU��?�ŋ�#��S�6��H�&Z��������DG�^�- �����1����^ow��~�9ϐ3��T����\�H��&���34������)��(��?�ga�1nI�:]�8�:[�P�N�e{}%�Y��ا�~�F�����r����8B�*|�j������ݸ�j�Qr�:8�*� �D꣯*%\�Umswh���x���0X�ܿ�d��	��ף�6b�VŐ=����S�^j쾳�/�<�t�>�5Z���н����v"�Q>�%\�J{uck�7o2~79ci�B�b�B�b?��cBN�0,�������ɿ��?�S�E�6��5����9����@t�&O����0�-`����X�ވbc2n�hJ��2yB�w�0�^�a�g��y�Q+�z��a��&���f,��P�<�0n"�^��7'� M���X�	��j��a��;�k����a���вNmFS5|��|�h's�������b��~���?&�3U�������*�G�YO���s@���f�}���o��yXO�@�0�AhaԈ���<I�i"��3��M^Ŗ ��
j��������U�DT��χ�z��;/(H}bY����OH���M�T�F#�6]E��0��t^��h`�$�B��tui��b���fg46��� ~)����5�*��+���0��_����s��&�E�p��V)��Ì@|_��á\�Η[m�-��0&�}n!�������D�ϊ�dR~��Ǥ@LV#�o��c2W��!�����2�J��E�/����e��x���i������ު[.4N��!����cr���V��p��$�Vx���A���T���T3rkF3�UL[#�S�u�D���7ɔ54-�G�'-0f;8�����f*����p����x�s����_QݱU�x7 �F4/�M5y����#'/��_�.��N�yA��W5�JZ�;NX1�F,]Ϗ|���2�� ���	�,גH9ړ��{��k2�{Ut�����La<��r�]-�a?]L^ʔ��A^ͬt��<�j+�R�p���٥�\��N��2]��9�7;�We�"���A�j�F2[���ۑܵ�!D���릐����޶��oM����%G �����'$KT
:��0�`<iLhS��\ Rd���Z7�R��j�t=�D�@s�@%��H��E����L��q�;�% ��0X�����Ң��	�Z��Fڍ�و��	�[���	4gʺ��3�pK��-�8|瞡�n���v<oH���E"ʭ��@
�ub�hZ�e5G�.$fd�`�A0bƚL�j��%JE"�����Q�bĶ"ݒav���JKƘ�,ۚ��
)dfamjrg@�	��`I](ܢl�0[ƿb�vb/�tS u�d/�v�8���"�#�)�� '*5<�-;�s��k���&��JJf��=�H�q�6bn�5t�V�<���X�*R�j��Mz��aא:��X�)�zU�5��$ݤ ؑh���|U���=yF��A(�#aP`ޣ�$,�f�VbKha�K�7;e Q��Z���Qy���Ԕ��`�;e��߃�6��j2s�d�z)��I[~�[T�w��yz'�P�7�-�FY����7�T�r� ��=J����]Km�~1.�#�d<1c�Yp��MX��}�Qi�>bW�B���)�(p�A¢n
袻n
��֣p����L`p�L�Qu'	]����� Cz��ET��7g�6�m�.� ;3�l��u)���3�Η�+,6��_�ؚ�w�HنČ7�U:����:+t�����j����av�Sgٮ�1��l�I'*3<�dy�F�s��P��TM�\�4��2�g��Jq�;Q�G��	ŏd�w:��#)m3�<�cw��qTޕ��1t!��n�!�9:v�S�u[�����gd��6ʈ,AN<L�Na�U�W4ɜ��<� ��+�v�o}��|!����:n�YE�4�M
g�C]�����0'�r͞�`F\M��"�q��ы�o�X^u���y2�&+��=�D�v9��P41�$��$R��Y�xd�t��5�
lcd�'u�DB#kH��q�
}bW��#�Ɲ��˨��"��@��� �@�ΨY6Rv�jF����cQ���f<�tc�fc:�8Нh�� ��p�!����n3E�0#�t�����d���I}SB�ד/ݹԈA����ЯϽ�2�ȗ����#�`g~���Dd:���Oe���\�	�I�88��$Ԋ�����'g
E9�)�����#�E����,k�Q�*ѡ�,1�U{s>W:ϸ�y�]�W�6��@�q&A9f���*G;~�uLɑ�,�xx����=|���d��)*Jt���x]���<3�GӅ�n-.�~h<�Mg�k�^�O���B�e������W{W�ApfIY�.� ����gA��L�����3&�"2��C�v3h�u���ѳG��/�5=y?qs�@�9���+7����=����diU�L�h�����^�FbE�������a��#�G��Fm
�S��}8a�%�L�y5Q���GX�T�9wf�z�`��8�����^�ʨ����i1l���)���?��+
�_���ɢ��j7FE�����������inXJ禋Gtߧ�a�)����a�o�
8�;�L�;�v�ʘ
;����M	@���_�?�q�E�읁=����P0_��w�꠮����Q}��sH�Ԡ���1��Tf)apL�]��Jj�4+�H={���)��6�15,���N��E�.��yW��	��qW�&��pGҾqq;�W��8�R�0�cW	�+ya�id�ۣ���aG4��B�������QK�Y�ނ@|e5Iooer�;UA݊���+�8w��b�y��eF �Z��9�~A��X��`:�W�Q���h�@��fQ�~E	�-���J��L��8�4�B���l��qE��כ(F�<f���3��w�d�^K%�d �X�GX�2a`�)���c�� )�$|2� ��QI��(
�xF�z<{	���ق2	�7����Mg�<~]�+�>bD��#&�
ب��LG`��<��é>G���@�=��p66�"��E"�eZ��&��u�M�-D��"��X�t��u�A���a�^���AQ�`�k���(Css�s��8��Y�K�wx�VD'��B��H�r��@0F{EN�F�Y��6���R��Ϭ���ø�⬲y�3�;��[�^,e��*`���ڙ�*\�8���)�
�\���Cw��s���h�]_d�\�v��Y��m� x_mf��vz��..��!����������d���m2؂�}�L�8����=H�~���&��we�@���UR��*�-��^7=��fʤ{D����éu'�l����K�h[����Q�M�I��d��~��(5 zM������G�Xb��U.�]vv��r��@aoG�ov�@{z;EPT,1���$�<���;�����#H��� 	�w���a�|�u
Ia�6'��Y@:�z	;5�W��a�E�˨�|�\�A]�?@���@���!�"�-f6���c�h1+ܑ(�Q6�<�Q�>f�^�D� ż'N�F� �  ��٫�{"3�W�]ݞ��x��)���D`'~� $9�*TJ������(�w&
T'	��� �s3�q�ι�i��8w��&M��fħE�Y�d�H��ׯ��u�H�K:8��o(����ߺ�װL�B��M���X�`����@����
�I�= EM��N���$*�r2��C��1��hg[�qTK^�Tp&��&�]��#�e�J\�hL�_�Vl\�z�Z/8D���yL�(s�d'����U,z��[a�8\Y���5&�~s�� ��,�	��1�8/�4v2G(�[Ԍ[�D�����	�cO9*��F�f:��'�u~�e�}E�7�`D���@�FW�0(5�7s��*MR��`~L�y��;����3q���'k�o�p��u�bԉĀ'�D|E�HAQ���>���c�Gd��?�������      E   7   x�3�4202�54�541Mtu�9��4 4�2¡����c��=...  7      @      x����n�ؒ&x-?�t�g�|��!Y��|�|��$J�E�2��w�y�`7���L�v���ܴ���X��k��4��ߖI���E�F+��e��-sk:��2�_`;?�������M�N��6,wItd�>�0-�M����xp��h'�����s�QQ�Y�G��ʧ�ѳ��lZ���a���h�S�:�C3�#�U�ޢ2���\��r3;w���������|Vh���h9�q���p���mu�^�4[����?�Չ�"ʗ?�p�,K�Q�����'���t>ײ�V���8��ͧ�ڧ��2��\q�Ak���x�(����-����,�y���a�n��;m���N;~H�YO~;��7/̉n�l:ϴ��k]��0��Ю�t��q�u��M3-�,�q��yk�����y���cb�9��p9�ia="<�v��̵�([c�U�y���#NZ�>=#�:�q���¼�S���i����@�ݖ�*,=n�f6�'�*���6�%��}^�XRz\ߥפ��a��m'�(_��OM{������$��#�R��,�7h�>�֤7��n]�������6K�v|ᅭ�)� 1+~;�S5fT���Hzp҂�[��V;ɪ��w�*ݨ��]�%a:�J\�i�����&�6]��u�G)n�,���*�E;�Bm��U���6o��fjX��pZ3��A8�'G�W�/+�����ܮ���[OY�k�u��R�f���P%,}�r�����%z.�"!�ֽ��Q��mZ�nu��I =۸\h�-�)
��8�j<��K�hC�H �2�:��q	ep�o�b���h��C�w\���N?�e6� w�:�n��h���#޸�����ܖ�tK�L���X���E����)�� ���"�ZV���X�v�Ӯ��ǟ`��&����?�ۼ_���Nw���`��%o�t'_����}�[n�j+�%~�¼�='a�ƛ,�I^��O�S�iY��S��mP+|�+h(���]Y<�=�	-�OO�[��8e%���N�
?�n��(�dCH�+���T���
X��
����:�o|�A/�,�����ۥ�����yU�������/�պ�R���l���#K�Ux��!����� ?�ő���<���X�GtސbY�!6$��r/>�=<��ӽ��� Py�|�!�VBNs�X��I{���8�r�Ғg������,�i��N�C��z�/=܍)��A��$�֠g�9���;��]���0H�R[�eؔy�
���Rd�f'n�'Eg�~1[OY�����Yq�M��n��@BmG�XC'���i�@;�d�J���ߐH���K�	���'��t7.���8Y$7�Q��^�Jc%��	�;������6J��iR%a��a9�$N�|�?��P[��'��?������_�%��+�X���( جL�A�kX�ڄGv��m�q
�ᰐ���8F�p��q8?�=�~[���H�ТV�t��r<�5�l
�ڑq�,`�nR�:_�e����H+H�V�B�"����	A����XѢ��Բ���2����-������m�>��DX$�6�)�^�q�G�AN��a��	��O�QZ�_�^U8Z�LW����"�����5�U�$�(^A��Y�,�`v��vݱ�xŖ'U�Mz��dٔ�C'!�vZ�K4��>K~���)�sC��4{s�V ��%߸�kҎ��ᄆ`>޷�u��n�b(�D�?��<;r���c���{�W��B�"�!:�5�C�Z�0X�*��c�U�}¤J5sO�0��Z�I�| �eOqe��U�� `?9��{�V}l"�ol#�uGyV��H�m�0n@�"����
��6HYbd !���N)�7�X���h�m�)� KB܉
�o�"��!n��͢�<�rAVb��#(��	�	#�#`�����09�0_j�[zy万7;��d-5h�<�nR;/5|=q'J��# ��n^���BؼpA�]M�h�_��4.d�E�O7Ϟ!P�������Ass���f��7j��}��G����zC��-	dV��������<��^�鎎
�#�����M,	\iK��^���W!��4�S�N�m!�$,�A�#m��,`�|�<�n�~�i�a��}�p5��ہ�����|�*���KB��ux�����i��)N8�V�fv��I���V�&|��<a�6	�a����h/��,-C�{�v�>E���yػ
&�(;��.M�Z����U���sJF.�hD����Ј6�v<��+sX�i�ї5�����Ėb-��w��@i��\_���g�;��II뚭n�.�#>g%ތ"M�ȩ ���䡸�F�C��#O�����"8�P�aMMJ�C�r� ?�4
�F��p��x�!@]���w�ݫ���#O�5�v:&��]VO��j\�,����#�!���n�����m�ac��@��{2`5�y�:�@�T��ֆ��gU�]g%����M���w�)$w��Gy����j#l���'�ۉWT�)]~�D/d� x�p��?��TSu5x@�٦��E��ÖPq�L���_b����<E��Oogp+8�@N)��F�e�<+�(=����p!?�X=���G��3�v��\��c�Cv��3� ƛ��Ц�∯?q�oG�A���d�������/�*�� _�5������z�Sm������o@Y��6̱���������ed��z��G+\w��?�Q��2���yQ�p�(�qee�{�*�A0�����B6'��T�O���oH��eB�ޔ��er��/h�w�4�I4�3���=pۗ�錰#��)�}q�ʍ�g76<j�����5��"t�����;�U	�N>��#D�v�[�:�&є��T*ɟv�ӧ1 �iM����s���У2��f�G���?�����Ke:���(�$���IXH�0�/g��Ow.C^�et}��#����QvZA��РN�*L��Z:;Ks�^,=����7�_��}��?�K[z6�+#'�� 0S��~Y�;�2����q��j����8��F+X)����(P�r��B�;RT��w`
z�yT�J��gȹE�eqp�w;��2z(�h�8�P8ʗp� h2L�-s��g)!����ŋvM�<���d�%���p��E�D�}�	�j������r,i-��i@��(�"��Jt���Sd�w��y�.��*/HG��8\�野-c�0'!��uS���GB��NR�R��6�/&�Wclӕ1)��\�e	 sO���[À��}�.�Z�`c��ؖ-CuW���<�x�t���$��׻&���3xUe�#�x����a'�筃cO����j��{c�v�`F!����ǰd�����'�����fH޳-�ϛ4~�]��"�総z�� �w��i�H_�������6K�KN!��:	S����nD�GDZ���G�j����5v*%�U;ťy��L{ '�uoBM6���x�ȁ�VX�0����q�y��M�i�� �]]��������V�?�.I$�tB��#>�o[s�[�=�ɶA��a#l�F�L�E@!b��M����VcȢ�7.�O%ޚ�#Cz��QQ%�C�j�_N]ң��t�.�u�Vjg10&YX{�U��������v�F�e��i�������=S��-@]��7p-��o�,�qx�υE�CZ%a���$��LF\���p��l�r�%v5��o���.��\�D�*���:xK�Ab��s�F ��<=l)�����ȱ�$�ʋ�G��Ğ6���T�I(Jf)6�^��<�1v0�@��Q�i�X���a=,�h���Cg�~_M��L�uy�ܿ`�0(��e�j���g鼊I��귥�]F��(+N�ѺPʬ՞���"m��UR�X[gyJ��^����� j�������1օ����#���ן	�e6�Ff}[�s�������S$�iW����UB�~ ��X��    ȃ��g�ztF`�[� Sa����hGA'5�EaD'�v{h�:��:�~�y�e+��(wk�#���ա��i�4��8X�ɝ��Vwv�8o��e�
�$�j( |�C�|�ֱ9���`܇�q��jp��W����tIA6ԴMOZ�h���pe�Q��Q%���e�:�jM��ց��'���un��Q:��ۊ���$J+x����AZ�SJn��~�1<6�v�B�a<�� b?֔�� �H�x-�T�b?� -Z�h�c�*K���n�-�=?g�!~�o��d��B9Z�>���w{��QLP[����$�8ƌs���bmn�� *�.	4���^�F�O[Q,����ӓ	+�p�>a�a]cs������!�J����)p�<����9�f�2�@9�a�P|�~���y�:q �g�,���?L��v�Vţ��m!�"���{�G��Dx�@�p��SJw� �.W�<.1V0���A|ܻ��3cUC���5�e�V�ӴA��Bo��$����ۓۆQ�m�%g�^�g5�c�Y�m"�#Ё�	�+���LI��P��eH	�F��!]}�uPE(����pr��VTcy��w�3���#�2 ��o�?�f۟e4��X��5��tm+�m�R
�ye����*/q�
J�sÅ�"<S�����N��/�I}�J"�꿌	��2��sFZ��cJ��I
01��Ք.�m��YA8^3B��p�C��#|f
u*BS�4�F)+�9�neo�L�P�_�q.B�G��c�Lf�: ��A�$Mg��\הX\AQ&������TE���V�O0�e�����(��e�U�������fC:��(P=NqW&z����ӂ{�F�"���XU�N@1nr�uݑ�lm��'!�-�9��w��5���i>��Q�r���tCq�k��:qʳ+l%K'O.;Dj`5��b��3!��Ʌ�|U��3@��i|5��� �b�p���a� ���y`�;yU��V �L�F"m��ML�T��s:� ��ir����s��,;Ni����� w%�>+V�$N�p����܃�8��
m�ۈWpE��90r�tN�ӿ�T���@���-sU��z�l�Oi�d⚗_�%f��5�����-~������ �C{�h?�*�w3�z���!����Ԍ,]��_�}�m����6-A�q9�Hٻ˯]����-A��CXL�.��W�U Q��eZ�P�����)r�m�������⫒���ȔQ�7O�6v1i�z���K��4"0[��.Ӹx�"�Gd�O
  0��Ҫ�	�w�4Ӓ:Ʀ-ޯr�1 TJ�=�ݼ�{���m�D8��K ���ވ�v�� �XD�,��V��^'Q)��
xh��L3ܘ�03כ��t	N�Ru��Y�a\�� y��+����8�N�7:�9t�A���A��y:�./�Bÿ��Ў{X F��F���m7��/�>kY�ӔCQ�"�rV��%?�i�Dp�JV*�qǇ.ۈ�T�$׺��9".��O��¾�W��4���{��<A>��p��W�����7�8N����׮~��Qbq���'`�����_DB��
a	4�7�R8���*i��lD�]ޙMR�N�����u�)���ɲ�G�xG7s�Y�3dԇB���l1B%E�M���a[k��2��G`O)I(�ɕ��S��"(���4�f��e�H����3�B���@�
=���\S�Q3~�^6��u���do2�a�>(�+�w"'�~	���ePUۙ��3�D�K���/��β��5B����ȪQ+	o�>�*&p�cU��� B i���nH&�',]8Βx	�Y��uj�h�/�"/�!pOekҼ"��B2́���dϲ��m�ҧ��1Υ�̳��ϼ@�WR�΢h�������n_y������ -��T�ֈjp|�	9�q�O�hUQ>���T?�A�,iM�>�I"S|W1<����?��>�cm������ST�<]Tq�^v�'i�:����5�3� ����c���Gx{��f�aݻ��T��Lr�c�6�P,��J�����r�'�h�1����&>SW�Tu?H�j�59z�0�P�K#}
ֲ^�^�u5�_@!E+���E�'@_8!2��	��R�d&oa�d�j����n\e;��+sP�E�#v��gD��e���6N!J�p;��M���C �Q�-I��@��(�و��~�v�9���9��YY���('@`6C§�\�N�l8�f�sv1C��9C�t��i_�dD����Z`���dð�,C��H�b=��5��	���M�8��G�DⰤlqp��J�h��!�e����9<�UBИ���R�l�ȷc���F��S��!���=y-W�vW�W\I��N��4��}��+�9=�j�����@��si̻\ò�Ҏp��8��i(�h���B/K����QB�n��fC��� �N�\���cW��)�Ӈ[�_�S�'�Ii����<����g���.��(���#��6Ԧ2�gDue����!�$���d7��S}�����˼}/��#�6�Ǟw��oϖ˓���,��wQí7�X�c�/�t������-)�0���h�
�<1�\b��7��$Z����� �tWѝcIη v�rX�ú���Ca�r{E��li�q1�r�=�����F�"JB �(��b�֪�T�Y|���u�B�L�8�T�޳�|��� ��Ӻ i��ڙ������`up��=5�:�$s���)㯿��O���8}#:D����g�H/5����njԮ��Ӑ������淍�ߛ�gu����IU!��E�	�)�İ�~�K���>����Q.�3�O���i������ů=]C@N�iT�D% ���6��]�
�tc�8�Dq�i)��ڞ'@�G�Z�dԮ|f�Q�n[
��^Ŏ)�/ݗ�%�1�� �L`L/� f�=&���1ndy��Cg��)�;`��?�P����B�{��,�%�#�ֿ�6�!@�u��@?���4,��w+�x� �:۲%`�:�!²e��U&��}	4-�)[�� � q����2���t%w�h����3���N�	�IHJ�VQ���{I���ܶ�A�$��iAt�������÷p� ,C��OR��"6�ǷK�T��9p��7��u8M5m'��'Ʌfn��3���O����ّ�R��7~���vLq\_�GI!�띦��B�(Ҿ8�1J{ˊ�	,maѯh����VT�{{߃`8V&�D0y�p�vO�	�s|<,o!e�B���WwX�ڼy�jڧ�f�9����9��r.�)6[7Kp���(\�߂Ǘ�SV�Pp�#�t������S$ę�t�n/�X�@��1�� ��b�ڳ� f�͟eH"G?&�Z=�CQ'�i�wcI����V��w��k����WR�\&~w������y|N�Q��?��-}au�?��m]�jߔ�K�mW����Ղ��ۇ�I��Om�u.��$����b���	���(׃gGb�l2�6~�l�,�Vc"9��)_�yWu��׳ ��A��V[��$�O�&�� 9��Zɻ�ͯ�[�og�����vÜ���Dl�N�]kk��,�Ó��k�ȿ�}��6|��b+��a�S��#b5\~�F�E0�$؆�}�1�������_����P��1L�$� �M� b�>�(������d�����,"����2����Qv}Y�Zs�� ^NA/NwwnGĻq�V78���x�W�C8ODYff�8.U�`��w�/��/<2��E!�"�rE��<���¶��T�LEQ��2�}tt�]�x�C������S�n�P��Ҍ{ÇgݖE��, J�tA����kʗ�JTƟe���)6�pDI�p	�& ���!LWt�<�RO�|[���hFÝ�?��q��>��9l聱�����&; @X�Xf��	~)���\P�������&�GJ�p�Ƭ��aTPI��3Sw    �"�G;q��n�ҳ���-�]��S'�&mr����6U���}�8���{'q����'a��v����}�
����QMOA[�^��|ǖ9 �"ejyI	W�m4�e�aNN�H��i7��2��>G�Gk�>�(H]ή\7N�"����ݽ�w�6��9�mu�m(J�B�g�=-�m���v��>�)��uUr�Qي>KK���aq���$"�*����);O�%�C�'�o���N�Ԭf\'d�}�?j�G�f��:+r��ү�&�<��h�)�0�C�:�ͶT����l��w���`�?�g�zR����Ϫ�x'�� NQ�^��ʇ�b�csZJ��Y����ӆ��RAZt�Ŧ,�����
`���8�*A�F��<c���7Tb<�z��j2�0\F%��a��kg�"���ݠ��ɴ���)����渌�)_K*����0V�\/u[��!y�g�$Zq9~{�ML���Tc杛bC� ���z ؅2��J�U�^�'�Vd����|W��[��6�1}���&�	�FD�K�6?�ݖ	��Ӝj{�z3h��
'qm��Z��/sP�
�l�6�������֐18�
��p�j;h�e���ږy]���f�X6�V�6L�r1)�q��*M�uI7k�,�`Ĝ��4&�YHA�!;S'���u�Q��
�]�8N������%c�v]����Y5Y��?��-l�w�䛹lr�O�	�K�}��@��ӑ�7W�ӮN�7_"`��:|�-|_�D����
�QT����u�mQN���oTk]��(N�e�q_zo�Jp`3X��ưL���Ѯ�~@V��EW��W��o\#
l�'��T��vY��\��r-�t,5$�y�,����fR4a��j���=d��v�	2�>`nK��{�b}��ۧ[_r��� ��:������_�;���"zHEl��`"u*h,��:s����վM��#yV�
P��Im��v$y.�0@�*���J(��+��{9�d������w�h��M,/�� �����AF����$�!�C(��w��F�����ۆ��s�B/a�T�a�P�I����A��v�N[��t�dT�1\��}���P*�a�oK j�s<�bI��
�6 Qߟ[PXu����ax0K8�Y��R[k��ȑ����;s �������b��QWC���!��8Ɍ��k ��Q?�A����A�58�B�	��$��0���m|6h`?!`�=�1�Pöu�c�p\�_}�n�b����X�ܨ�!���s�8���g'�<�E�bC+�6S�N/gX[���"x�-�t�M�6�'}��\/���Jb
��&��>+���8��X!�97���������Y������Ae�N.odӶd�Aԕw�9�T�Ų���{��2sI�dr�u8^���( ��'��5����s,|YI��l�c̬��ņ0�P�3�!!����R0��}�K�Td�Up��Kȳ��W!����akM+mF�,�:H�׉��I���R���a�YR��:����M�f��L2�O큃U_��f�"4/�����6
�`:?-��T����L[��Xs���5��V ���붺���<��q�Ӟ�8��VDm � cd�����$�j����o�i���]8�����߉�zW6��PH�©�_�'��ƧOuG��@��°h�V�+֥�?=�����*^R'�%�~�9	+4[j8�O�
�H�%+C`g���qd�=0>{����S�����
"y�x8c��=��$\��W8X�&��_��y��e��+��c�25:�mY]G��<G"����؉�&8I��F'1��=>��T��'�Vcz6l;�D�Bg��DqZQ�E�.�7���#\ź��A}�/f����>F��HcES�%�-�iJ��z��LQ�f�2B:�!�mB��bK�`�3�}U"s���r����԰sgħ��8����}lD���Ԩ#�/�($��P8Zxa��L�۾�(�g�6H��9�u`2}�"�?5=[�R2Ɩ�h1~:�ɷX􉱸��.��lJ�!�h�������n�Jɓ� ����kT�x<�,�v���җg�>9�ܨ��$l�ˈ:>�he�?>�������6�y
o�7�+��D��"�)W���9KC��of�ߟ��--��j'"��N8QŖ�����E������D�,��mQ�ܥ�X ��	P	�U~�HZǗ�7�3-��jCf}�,���1%�֓�	d��&/D�e}#6����x�� �;�c:Z��Z;���I̽H�s�Ӯ�8*Y��ߣErO4r�=�/a�cL$%`,WML�_Rrê���|=yP���[ܜ!�)�ZG��i��~�}<�س�*�����Z*R�lz�PRs�&I���w� ������5ɨĶ~bE,��7�+����\�kl���.��-�;�����M��oO�� ۿ��UK�*_�}:�${����DʗQ�a?�?Җi<&��d��i�XBX3�lM=Z/����>��ΐ�W�;�d7!)��=��j����D՜Tg��J�-O1#��uEdSH��S@�;��	���D�q[��z��+��=t G�|*��f���߭�C�\�J�s7�(�t(T��k��-��T��������Z��]P���i�����q=�<Sp��nƓS��Π�=�L�X�����΢�bZ1�c��doN>�H���E�<�Y�M5��z��&d^E���;aPK�hZ���Z�@��*7����N�Jki5�q�7]��I�����|�Դ���>x��)b�I�S��nn�5 ���gHU�6����Bn��,cF�������;'�d��ᛄy�YCfqdC����*�ERG �(K+�+r��
}9�5�I�/��_P-����́'�K�!�d��(�Q�Z��&�)�~82�/�B����=�p�"6Vr�ud��������}��@���� �$O<0%<T
y[�~x��E%�-��LI�j� �I����]�P4�-����.��-�(�'y�|"�Bz\\xT6�k�b���Ēq��[��Bf�2�i�O��yC����P�ָ�".y�}׫�5�@� ��7\e�9�v�;�!.�N�V}c�����/`��Q�ꇛ� J�e��bd�Ƥ%��W�G�>�����x�ȳ�T�,�����pN}�ܚoI����#�mxD�%p$������(2*Sm���rm^%�Y�H�ه����2#o�(\�6YE��ԑNW�P��I����g�z.��-cf	q�A�L�������RjK��w��^�,�TI���yo�)�M��e���r�L�;\hn���;�WShG߫~��^�}��P?��څząպJ���*���ى_}��JT���r�'�#�k�l���R�^�3y�G��.��L�����K�4=��m�a�.?��@?�L[آ�bE��NV��(��1��+ ��bjT�H��8�AZ���e_�-FlO�����1�Q�}�� [Z�L�2$q�g�X�j�
�d���4�����7�.��W��ڝ���	�.�� �uo�����i��P����C�(���F��\�}D��K�@^��,p,Y�/�8�V��}�֓xߐ�a��ϧ�����K��I8���h�����Ӕ���&�E����Q�Ч�^���=@��A���j��h�mI| ���U���koI^u�L���:܄����*|�4%�VV|��7k�����F�k��q�i��h��_�G�2K�U<��7�u��y��D]���R�`	�qJ��D���l�g��@~Y�m�q��gRs��ɮ�B���yg4C�c�+����H��E����K8N���
b[2#���1�T�'��[r�9��#۫<��Pv���Ƹ�j^���j��X�-b�<�ޒ��<|���ߟ_���0�\�2c�^F^���M���;KR������e�K����5z��Y�15�ˈB��D���d������^�Zu�u,s�Lr�Q�Ϟ��Y-wߢ��$����w�=�ak�L+"��"�Ư�Z��'    ���R�)��"Z
ݬ�p"�~|3O�h�kG�O*���Tt6�7C�1mISr���ў�a7ð��Z2�muy[�^�.C���p�q��"����qZ7���E��L�Q3����֗��kJ�<� 'і�g�l�!.~<��D^��SHzW��.�qd�Z�	\m7��ϣI��M�C��'�6M��NVMòސ���&y��E7ျ�P�Ϊ�Gvdۊ،�.�hM	C8{x ��_w�U<��[dI֋�YA$+ޫ��?��}뵿�-I)���`3N���m�����b"h���>��2T4F�*�Ԏ���X�B�!Y����ۣ_]F๡�0�dS��l��-����0�)�E�S��qM٢�$��{P4����zǱ�14������W�1�<{����l��M�8/���R�[Ϻ�{83��3u	��m6m5.�p�{1}�ޯ����"Ge;���\<_R�Ǔ�W`�L,9v�l���9�U�e�#DDm�RX�oM%v���%"=~M�2���=�u3&7��c|\��Ľ�ky��][��ի�Ɇ�T�xV������є�㒭���\��&Ji!�q�n�2pN�e��Ff�^�#���
���R���|�� �m���?�l ��%7*&�R[ �.�������E�L��Vi�Sok��G���ѱ\1-�=��VM�$����*A�����d��]�s�Ol{�h���¨䄍���8�ܐ��eH �mu�IpNd&�U����]����jo�_�.|����`O���f�z��̥�$xp����z����5�M���RZA ��'�a���F�C�����B�r�H�,B�F�g6�NòЈ[�G��
ͼ��vD�/�y�DU��[S�Lxֲ�J0﹒eq�i��2�P�*�4�aϰD�ٓ�7Sb�k��J(D2��9�#�\_P�_��t�C�ߢ�����nVw��
;����>��Щ�zy��*�+̧�e��s�F�pJ���>:N�j�&��e��U�w�������a���0p n\�]PJ�Y���}�W7Dp��fڂ9���"�9��m�}׮����0���Wab�����5?�<�5�y١�zIȏN�Mq��V��3ۦ!�F���Ї5W��!��T)8�X)�=8��Σ3��� ���AA��"�2O��$!jG�#�n�Sf �F�g�@1�261o���8U��(�KI�����"��E6��N~��\�P�69�&����F�����J�c[<K�w�q��h� �A/�y���@dD��T5o7�Q��g�J�d�xu����V�=g+�a��^C�\�:6�����$*�D}#�������In�8�+|�pG���:������c�V�&-��)(��fOk���׿.Bm��_�J[b�����E��y���@���P���2�j`uyw����0u�x�%�ف�V���̑��h�c�Re���N6�ߐ��:�zQ�k�9���mSp����0q�Λ���DA=-��4��De�1��Bp-�ֿF��zN�"�lG1�i��EUi؜kqvT}4Ϧ'm45q^c���8��K_0��qZPݱ݈�����1�k>IB7
�L2�[+���bK����ҝ�R��N:h)��وP�ȳ�hªM*�Du�*�;�iG��p�f��#}'��@Џ�����)q[����>����S8���E��w��ﻸue"ή����}<��]v3h{�>S�:|)�<=tۑ�$�^ߏ���vݔ���tW���o�$��ʵ{�
�.���t%L�8� x��Q�.���ጟ~������Q4Y����[��n� ��yw�1_�I|�������FMs'�d������k+V/�.FT-�/
GB��,��e�;Rt�]wr�`�cօw��~�M0����Z����� +B8����{1��@����-9�M��a8c��'���;��V͓�9�oF��u���0�^�9�̯o�"**��^���f���UONu�M٬M���ڸg�C�����6�?���+λ�`�M?��N��H�Y������[G`w=z
d�v�Gq��hPs:[ޢ<���i�]ǩ����]��!q�6#�W����xVD���P�U��~c��?�3��i	C_Lev)Lq��;������]K�1�P�(�Z��ӫ��뤐˕�ԓ(�m&di��%�T�R�xH"$�����E��`S�s랮�KOt&S�K���\'�oL��|~�e�[���u&M����$\s�����iH֕�SOQ���	�ZS� ^u3�[�x;G���0r�b���@@{Iԇ���,)S���.�����`Q�Z���K�u��]-=S��MD�@���>�!d�o�:e�,��Ge �ck7<y���@Ǔ)p�0���}�i�TQ��_�'B�.�+~��v��S�'ة�|�����K6�qd�Y�;����5!�Zn���*%���!��z�8#�Δ�1<�dQ�+��H��8Q�ٜ�Ϯ��s��qͷ䧟�Q?��/�2�hICE�KhHv���% ��Q�a���G7j)N�&}��2��8R{��%w*��ο����f���Lg�������!�.���*��N#���-�#��%�qǑƌ �F�>������`�K������t>��9d��0��#�dj����X4�ȷdWG���{L��}�?¬����K���!r�}sқ7U�.E�,�gV�̩v�8�&Sr�M쇋*��n2l�~5�R�:e��p��^��o!6�� �̮��"�<n�*�5�[7o�+K{]��#6I ��`ıP&��\��A_���:&7s�_�pa���i���|;~����u�0��1���3�-� �/7�,�{*�������Dk;K	e
��kQk|�jT��A�np7�N�ñ�r=v|9�J�X�ct	�	{�3{�U��O�_EL\���m����:>]���Y��*�<���k���t�2���M��r������D��:+E&2�$)	�����u�b`�dS]��!����"?}�t�!����ɢ��<e�঩J]�M��ҋd~~�����d���˷@�I|Y<�D$�UD� ����!j%z9����9�9��'A_�)A�y:�e�xOpF#�͈ܿO#��2�"����������.��+*���$0M��ZF	t�F�F���q9T�1d�S�,�L��' |	0ڌG�C�b��SF�������y���dN73W/��Q�<̱��Q:!�d[�c��NSwӂ?&��(��c�m-�E�>��OT��/8Ae��=�;�h��U�������qCDCXς�7���~6��L�8�l�����y��Z�%"�4�]��H�=��?YBu,�nR��z�U��ٻ�H6���0�����E�.ӕ��c���q|C��wj,柈|�O��>E����3�ʤ)k���i�g���o˘8�"T��{����$W��k��T�pYRo����ד�3Ta�<y�eE��U)���w*�C �O'����A׺j���l0�X�Q=����"B��Y8��E�{ N7K�肢G�#{����A��-Hś�J>�\.��X�Z�$&p��D��^3=�w?}C��0dl���Y4!�̱���Om��פ$�ӌd�7/4����ȆK�u��)G�@� �㴃ռ�p��%�q���4\T�������z
�~�Ϯs��Ɗ}���!�IM1V����y6���c"Jk�XI�f�1�����Ikܘ��&�1
��E��v<Eh���d�y��Ǯ�K����D�bp<ş�{[*�� ���Ss�<�&�}������Ŧ�?�}�p�r�d�W1�(Oe�����V��lIŃ^�=r%���QyďӇ8h�9�#9��Nj��[}r��p�}9�>t�"]HY�WXr�D$I,��$�v""����t�}�l�"���-��p��I�ю�����64V� ��G
|�hܬ��<+z���}��04�O0P��f���7O����a!�ٷP��=�MY)mx2Kp�)(4'#	9^��o�nL|����YP�Tj    �������m��
n͎�S�U���e����
Hl���Xq�6��v/�±Z�����/�,S7p��(&�Y��xӒ�A�Y��$/��i��`���t,������k�����1)�Htt��H���(��S�ޟ�R�I6�A���|\?����.tO&#u�SK|���]ubJ�,�$9�аx��B�9M��˯�����~b|� ��9�O*Q�V���)J�ú�<Sv<<I��ə�{h��|kڰX�mX�Y�O���С*3�<��>� ?�ƾ퇽fi	K�+2�I3�ԭ�jV��K�w�Z�˞-�i�%޵5nP���ס/�s�/����?i�01+K��+�H6��6��v9>,j;����^�Y5#L@@�*&;��h����x:Fa�b4X��O�41�n���o1h���cR�¥����ה��"�}qK��|i������֮!�~H����ǜ�r�c��ş���5�V���	G0)sOF��՘h8j�LY@����e�*��`5�0Z��������6�I�ޱ�C?��zF�b�L�gpb$N�Q<�v/�,R�D�cb�҃)�[=_��7f�����:{U�[�����[f��}��ͨT�ĭP	�ϩB��649��H	J~��%�4�aEbq��d�ݒڗ�Y%c�j���R?�D>1偊m�j�(�ŕ�4�.L5
gNc��"�i�Z^F���5�V݇�@�7Dh�m6W~)u/��|Wu�^'�&-�*�,B��.?7I�����zzM ��S1���4����NO�i_�{�?̸aE=�z!Guq�! ���M��0�F��#p��i�n<��Q����m��1� >��:�V��UP�:;R��)���o|�WӸ7�ɣ�6�Q�4�s�u>������DX�'�0�:�G�Y�T��$U����W
eYu�,��Q��B�\��7���eJͬ���nk��T2�Γ9��'49\K��+���Ր�8�ˀ��~�(�8īX�Rw�T�ǐ7\���]"De�E_#��2`Cl+0�Ҿ�W��hL7]��dz���nQ��«�?3Yu�gr��D����o�?�I�]S%����W�{z9�l���0�8Z)��κ���M��ttH�3� *�>�ٲ6^�TaW`��0"��
D�Te��ͽH�PE��9@n�}|a�y_�_s��MQ��vS�|֩ˠ-^P�F�0]�X�m�/ pY��:_���m�gIL@K�7� P_x�������ns����?v:Ͼ$�,���h�=��7E�����&{o$IE��J֛�ڲ����s{�'���hj�	��s��<�z�z;��h�ߛn�'nϞ?<9�
dK�N��5�zo<������\C5���Ǘc-���2�������B����v� ���)�#��G��~v�����z���)�Do���-2n�%[�`�S�ل(܆2���T�Ϸ�J�����x����j���S"�0��̊��e&�U��mNn�)�_�&a��#]CS�(���lSFt})��RS����ՊbW�~�Y~�	dU���pը����\�V?��	j�u���Y%��8�9Ψ�pc�$h�[yr��.��' )����ؽ!It�|�u���_p�
i��ٹ�I��+�{�*��l�<�{��~�����GqN��D���0��Dzl�[+7�G�=1nQ|��;��׎��"��'
�j���N�\T����U�OQ2�LL�{��	��o4�Ҝ�w�. ��mɚ�#���'�ܴ�1WjbǿW�z�nD��t�^��Y�<�c�V��3�hJNRD鷺jSITK��p�+A���{D2�Y���z{���b|jlD�J�޾�R�0���ԪG����N�d8�Q�s���֡��#��	�QS���
���E���L0���F���^�	"p����򝓼ɽ�l��Ϩ ���M�����ި*`'ݛ�i&�Z��pZ>�Gӟ�3��	Q�&�g���[*���x��<9{H����{� Y�m8����C���RӬ�����I:w��ʸ���d��W��Q�'���Rzz~�wĖsAϲ顶��M?}�9$�nTѢ��w��D�K{~����M�*LL�b>a����.S:��mtΰ7�+_����I:Te��6k��R�x��:�^��<�'�JM�*ߨ��ӺC�8��aꨬL��r�)8<�xpn��&a�i�P\�[��Y��%����\n�Q%��o��+o�wh�Cql��I��x{��<kY�+\�{"�S<�ۗC0����wS���C�vI���k������YTG�u"z��Ȅd�<�����5�ɬ���A�m�p�"v�@�ڬ���w�*T�S����Z���|��C*a������5�=i_���"�_`�ue�~�A����L4C�E�5o:��)�n��x�]�w����O��L�E�d���p�p=nw`�h��J�K�,q��m���.�P�<N>x���Ɠ�D[�;�J�E�"_�tG}��W�Ά���),c\3I�tM���
�vuW<ɝ��qQ���'8�y����D�+��a�ݩ��G�$UqFM��:��C++����[ˌ�{M�����>rJP�tB���8�,�C��4�����8��R�ԈW@���������?��˻�7�iFӐ�QO�uI1a4�8�rl%'b��-\8�>m����^�"g���E��=ѩ�.��_�w� �Ao7�.��~�BO��DZ�+I��Ř��0��=nS/��*�h�x}rg�2��`XS�H��erV��g��dQO�u����x(H��^tF7���hN�+��J�p��&�'%�ە�j�X2��m��c���fA����pv�1�+��@��^���~ߐ���t���<ד�n4
C�@�����Dח��{���q4���F�.�����w꣞�)�w�Ey��"�q��q�����g��
Ԍs����^�a��H������J��}��I���u�E�q�"(��˕�*�\vѓ-/��(c�ő��e���=�ԝz&��۟¥tf=�5����#;ہ�&�,�����#5G#v*U�)���睄d^= �%ϳ�'5*;M�|�YJ�8��"%Bf��[�1-I�.����M�Gi����.Km=��W���x;5�hK�������|v�YDAv���m2�A�x���t��$��U��j� +*�����H����F���`�#�EE8��Ě¦�Ǥ��#�Q4q����	���f_�'��Bk��~)�n������nT.��=��|�=��.��%�1\�+�X[<+X":1����
�Om�cꈝ���qbE�Nŭ(��ĵ���݋�@?���a���L�rxl��}�`h?�Aĳ{�,0��j����B_�q�>ͱ�;F�0��(`X��'�"U3R�����T#�~v}�+(��C�.�T����d�Ӕ���?��4�k1�aM��*���$dS�)u�8� vQPP�\T`@�E��BAd!HDꖚ�J4����o��,K��'J�T�Z'���x	�ˊ���:���t���uŒ˭���1�A��:��o'�U=�H�q��ߐ0���wpI7O���Q���S,q��n?��Lܻ��뒳G�uwY��RZ��0�3�����.���&��qͿ��E5w��E.�=D��U���2LM�+J�ц��1��\��+*܈���PXzA�a��(3�֕4~�)'Ȍm��jRدw[j�kJHtʅ�ٙ��<u�C��>�K<��d}~�-p����ɸ[O�Z��>Yp+7���C�֣�I[z)���2܆8�1��fI7�� QW�8�!�}��{j�}o^�af���i��s�AF����3MO�4<5��:~7em���>�#�$\��'�45B��'�T�(�@�R�2�y�Dq�� ��|��Ǯa�[,c����ɡ;Ie�*��K�ld�*Bm	[�H��:�/�U	�.bݦo�|81�_q�M���ڮ ^s3dq���ϼa��
w��0d�Ma��8��eQa1�S?p:N>(��    ,�����"�u+����O�p�Ef�;��:�y{�J<kI�Ê̫Hl(j�؃������h�����%��v��^�Ȅ����|()�#�{������O4��hA���j�Ү�
&8��=���Ok��eJc �	���ɣ(�`C�������;6����:aͨIǙh�1%ǀ
7�(i�Y�U�4[Gv�2�ۢ�TD�%7ԳTy�]&W~�w̕��,���"\̸y��TY
�6	�\B�m�D��q����驺>���<\Q,���gSH�S;MO3F�'�D��ڔ�5M�e�85��oS���p�9�c�JrM��U$�q!YZ.�EA�M�������ᒈ�4nU�Р'����T��n	�.F�MS ʦ�6�������.�͂0�sʘ�~��9��.�i�\��l{n�	ؾRg��V=x����6B0is��P7|%<.��l��oS�}�^QvN9j7�`�'w���1��Ԟ'���_LV�M4� ��r�q��6t�6�v��c�SP�J�0]r���n�ܴ�i�++�N��f��	������l�zN�ƔG8K�`h��AY\_w8��U��&2�*	�R�/ [��?��X|�Q���"�EQ#�sàv୚eU}�����O��eK��oQ��*���&��6���^���S<����q����zӕaΓp�S�j ��[�wњb:/�Fa[�lZ���(I�DQ�u�7�*ۼwz�L�M�.d�q�f�E6&�(��cBz��~�=5���;����?)?S2{\�f�M�ET���uk9�[�j��iE�Hu�?�;QXi<i���yMby�[Ѩ�zx��DJWK�ih��K�_ɹ����$붗�خ4��6��ho!����G�
��;��x��AdiM�%�s�B�ȟ�$�+u��c��LЮn���ϩ���͡F/��gU�sR=��I�ͧ�Mri��O��_y��Ͼ��фq<_�U�[�l^�&���*�����pXN�H�r�4��X�G����)N����r}R��6��E�:Rp}c���e h?c�{���)~��q��#R�$��|'�nJ:�#�oS�fE�E8n�"�Y��eIdD�u_��P���z�7ŬC��C�n�uF<D����jŕ�K�1��~�+6f/]w.	TlOr#�h�������*^��Q��IY�lOFmɷ�o��� �i ��j2�d�UӔa��:����i���&���/���W�U}�7!v0P�/8^��?GW#S��D��W�mz^ã���}%�d�����,lO�����9M�� G��U���;�e� ���(�>%�E
b#�~3\]���g�S��yB	�;��YR�[8�K�]=U�	��IE�NC�d�뱎;U�������F���$/��.�ɸ�ojV&8m_����&s���CԲ��W�W�{U�u[}C&_�x�QωR�}#���tG��d�2�!�W���ښ8Iu�:O�+}O��{�8�/Z�ʹ=��>�	���븓�pȬ��N搩L[4�AB�-��N���t�z�tb<I��{�P�#�(�6��{jo��]���_�3n�����%�e����m�9���%���S��,�s���g4&���U�3MI7�����pC�֦q8K�$U�>pD�FǗ��"q�A���U$T�SC�B��=5Ҏ�+#�b�2Z�̤K��Z�+�wC�<�o'�A�e`��P̦����ނL�.}`nv����᦭�W��ň��;-q���is�j�$�Ȑa��p��F���o_�oے�������&&���A�Uzw:7�^�X6䤍@4�����R��༃�=�i>�-��-�qjޓ�dio�E۔c0��F�p؋R��9�L����Ur�DNG�;À�f���w�ױ����/+�c`h��&���2Y4���j�-�IG~c�߲3<�e31��ɑV<���6'$ܝN9�Dr[�Q,�Ͻ^u�ՄK@S`?�x��� {x��J!:��`�8��Q,�zg��"a|~f�F�/���yIU��>β�j(��9;���^.�X'�i�;���P�.�:�&p mG�=#� ��GlpꎄG��
�7ԡ�e0�n�0ۤ(�ǘ5N��C��giS�=&�������'V�YS_x�|�H��+��]�6d-����74s�Z."�����|{Z��V<�g����Ӷ�X[�4��W[�/��#�fn�~�;n��<2e@c'���L����~�ԝ�x3Rխ�<`v��z�$GT�=�wwm�>ݑ��<�4\��J�^��VF=�ɑt�A<L]��*����MKqtYNz���!�f�i��p�����@T,p�S4���yT&Yk�oA߰v-Y?���~ژ�ȶg)Q��e�R#��$��hΞ6\�k�$m����r�9BtA:���is|���)y%#x��!���:��W<#���ő�@דLU���J��+T�^y�P��z�4�0��Z�o��a����Z\S�u4��	�`p^Ğ<��P�r`� ���W����_e^��n��H��OpBD�������6%��:�l��c��n;HN��˫ʭ>�n˺	F :U]�����̍��ųeKzW���$��ѱ��Je��֞ӷ��|�4�e�z��g�%k|�޹�q�}7�����K�V�<K��Z3�ɦ����W�e.f`�xGe�j�l�k ;�ɱ~8�Op�V�N�5�(>I��L���%L����:M�ᜂ����<�Z��|\�����9�PTK���%��S^Ӕ�F.I�ؽ����զ�k�x�ITud���>���#|��96��\k�R)���ؕl'�$ѵ���j��G��x�x��d�����ӫ�����c72������UE2H�Ȉ7��uS����ڡ���}��^	���>ź>ʪ���X9B/�C9�yl
�:��X��n�	"M)w\�YA7�v���
;}ޯ����u�A��%�����瀪�q�3z���(Q�t�V��ֻ3_�M�+�����~��v�~�]�K��XoǛ���'=ef4Vs�a�{��F)]��S�m-�p��,W]b���`1���y �EA`Nf���C�,a˩�Rr_y!���&A��"�w�Y�YcNH(������;Gn��x�Heg|8}�<R�l=��ʾ��5?Aȋ/ό�Z�H��0JcJt��GG�F)&<�T�m3��K@M[��1���5Z�\�)	��&��p�+D-g�T "~�A��p�g�5�ޒ���:���l2���24��%� S�F�ш��E���v\�+S����΄$�����I��t�0��r��ug"Dp4�枨��KA�J��k�mhO��y^#��ћ���id�=e�����Xji��&���Ҭ\�~-=��<CJ�Jj�
B�Ĉm����QWE�_�nJ|��Gyb�H�4�Ii�<qX�/��}S��UMI��M
ּ�W�;�I��#2��L�~oL�(;J��8k_XG�L��j���d�;-�ګ�o&P��K-����!
��N�g6�w}r�JI�t�>o�|�����;qO.{��Z�&=w�#1�1eՃ6�Ú�[���z;�n_�Ŝrd�5؈m�؛�v�+�5z���!��p�/>�a],���&�O����ѐE��2R���]�R�4y�@�?\l����bi:��~ʀCV c".D��X?6�X�~$�����+|HEm�"�<I�}�XCЕҧۢ�ёB���*�((}H��L���[��nN�ɔ��:Z����C4�����؎O*���-������B��}G�ҴQ���\���G������|��D�~ۨ.��4 Ĕ]�l���dV��EFǨ�C�Ne��ߚ~�&�eE2��P�;����J�@鍮�?��rR�rG���V��\��X�@��&bk�#EwK�3}��e
��άEJ'�|y:f�,��;(�������g]m�q�����Σ�I;�%/�B�����5"Jlo�y�e2r$�%��!�T����O��Q$��:����*�nT���&=t��#ĸw5Z��ޞ� m��d�^nq)f��   �>�_XO�i�Kk?a�Lw Ю���+4�5��.u�q�@b6����W��\d����l�@X��u|�������]a�����
=ot����7���S8��ߦ��ZQ�Qw�j6f<z��r��Y[УX�<F�֓���M�S
�8J��|h(�t+��tDT�p��W$�����I�;y�+N�4�s�1�7��8�4P��F�fdĎ�̯���娩h��d��͒6+N?BJ;V�¯5P#T�l��+%�mg������ߪ�'�o���޸�{���#hȃ��w܉�&��vɚ�ɬ6N�8� ��Um��~\z�!�����_�*�N����%��C}cU�O�� �FK*	�v{�����0��@�O`�
��� .v���؜��ðO\<%�RTG����t$��.��l1XE��h���w��m�12u�i�Jd*?�M�^КJ�y~��\_�B��ԅ(Ї=�Za��ū�82�Hrhr�@Ҟ����Sd��2�}O�( �����v��;���=���:RȾ�gJU�/�}�̺�0K��XkI9vL��UKwt��#�,�����!m�W?i3�G0�����0�G�k�n��l�J?E�bD��p'���z�:�/��â.�@�<�;9��Қ���Ց��g4�4F;���C1�T>m�Ǽ�x�ҫ&�b�,�˞�k,�yɣ�Xhcҽl9~EƋ�
�Q>O6����
څ���P��su����LJe�ҋ�r�ڭ.��gK.R؉��VX�Z�xP��ԂԴ���5�(���Q �yw��H�RL���ǒ[������>�͍����S��j�h�7PvNU�~���%����l��X����g��}Ӻг{�l6��l����3�x8�v�~���l���Wt�ئ/�� 5�[C�+vJ�\������*�샤��*�}�7[�k�M�*�_�h�F|�ޥ9�g�+U3.v~�w;ݥ�=�^��-.��1�!�SuO��+���XBCw�<�8��Hv��P�����m���g#m5��0���T<w�ْ'�>�B�A��#V��֧��@�VF�i�U�M�^��XD��u׸w�0�J�ӯ�����*R��mC�Q�ϡߘ�(�њC��zV��/3r2x[��Kt�̯��&����z��PV��R�OwJ�;M���ϩ£W����[�(06�Eh$���Daq]��N��?H����L����g��@\o]x2�Rf���~wmd�UE$?kܛ��(�`S;�Yja�dQ�X{�k,A��V
y]�oC:�D��B���O�	�l���ɚ��a�7F�&�X���37g�t��D��ө���B���/'���l�s�gK����C�B����zlh��&[�_�k��{�^s���h�ud�x�,�pTM
����Fݸ��l�������*.�t��x�N���

Ԟ���k�JG�2�Ǆ�'�О��®�y��J��֍m!]�����7�w��$O� ޤj&TGk�������?�O��i�kl���x��-Ⱥ�09�����:��-Xm}/�B�)UH�oQPp��Z飶n������T�׻n?�����%59�T0����|�}������j�����RS�ô�Aiq����W0Bf�0r��aĀ�d�cd����u�0ubWt����e���=$UT�,v�<���$���t���s�m5"=��鶙��Z��,+�ym��R2k����tV�n20P�J| Z'D`�'�y�����C����&���*�Z��l���R�J��N>��mz�
���s��都�3}h�4�q*��^���3Fy����f';�����zJ�#�����Gt2�W�򂟣n��i�<՚e1=U=��lz{ 0bAL�������:"1w.�5����#=�T�셀h��5W���/_� ��|̓�U�Ye�8�:����##��4�.��	V�j?{��cI!��Ĉ���ɒ-y6s����J:}~�]�ܺ�1C�(�*������/�,�!t�j�,��������2l���F��v�������v�K��&��'���/�s�ݓSל�0���8�$~R�`RG��$uGB ���'e��
�þΩz=R�8�>�]S���d|�������g��+
��U��<<\�\
C3���������&�ph>���Ͱ`�%C�U���߻Xl U$��0꥗�'2��E�n�A�ė��.�;�vK�o��Jl�3Ê�EV�h�һ�VM��v�S��Oi��W��B��뼸����~��c�`'���թ#�zp����Cd��
�_"��+-�d�����z���iS����*�� ��0�F�b�%	�0N��U�Vi?��PJ�'j�y��W�v��( �6rf�!��Q�:���#7��߫共T}�K�����w�*������5	��"2v��{�������CɁ^w�4�bh:�M10L�nE��3�{�4[�Q PѺA�p�#�v��7-a���r>�/�ʢ���ݍt�,A��M:�l�o�%3_Ԑ=%�^����Z��6��jݵ�P��'��\&착��|^�G���9Z��'ǌ^)��5%u�!|u�4���h�*�w!T��f�\ƞ�9��a��@�����}��u�L�t�.p=`�6�%m�w�W�"�D�M35LA$#��H� �g�*rЭ�n{/�h��2����4$�)�i�5�ݻQ=��(��=X�7&���T/��2��x��n.�$!lA�株nZ0��.����6 /�Adjx��E���8==�/�ɾ�      <     x����r����O�'p��ϑ�$J��P��_��XإI�������,
3t��9��UY�Y=޼��q7��Co�z�/6�wO��ӗ��7>�^��&vl4?���v�?���I���[�1�m2�O���p=L&�ZSu���n����၍�+1���:[��i���3��+&�l��û�����xQ3��?�]�*��X�)1G�͛��~0)�Ps�&��w��CK�%o�B���s��'�i>$��0Nywj����ɵ8��f��#m�ݲ������O��$�[�7���%[�`bI����K�����������q8r��յnb��˃g�\��B�ۃ��|����u��q�{29%�b�n�r��R-%E���6�/>՞:��ц`�N�����H�o��}���7E"���nr�����$�\]���t���������R�X�[��,��.S�bRO�S����q�)"�k��Dםx��'RJa��>��U%OjB����f	ᜣ�ʔrO6z���x�� -��R2EY���f����t�'�����o�ݥ�sԘ��d�|�o�~??~��]s�Zsr�n�
������V<[��+ټ�#�Y
��a>i�9q1�w�hK	)�>f��a����n�_�4N��x��Lˉ*�Z�-�)���c��6��q?~y�Լ/d��]`S�,���"�<� <o�=�m/�W���jӊ��{
�WS�M+�)5m��)�qz�%����EPS}�ŗZH�i.�+Nx��Q�:��/9�>�% �yҜݒ~ZTp*v�6/�ϴ�'�������bH$�q��h>��W���c�F@΢�������F�/�����7.�ߜ�����vs�$�NG#6��Ã�Hpg�X��f����8̏���iH` �����K"������~�j��^��/�5�ND+�Q%,,F<�Ud ��ąR�547G�lٞe��Q��ö�ss�\�_�K-4�A^IJg =.ڲ>B	dB���9�$�Mڣ�o��q'�&.dh���/�)��67�i.�P�&@���5�ov�9�1yO!��n�
��'Ԫ�M+�E/��>�}6��>�$Xw����Jc���C�J�0�����DӇC"-�"u˫-���?��~)���W �]�A~f� d�)Q!w�� h��?��C����$���.�8����/q�x��*^�ږΉ
p�x=�\-�پd����jeIW���FzS��.����S�����v��у(- �X��|I����I�}����H��v�,h'	Lh�EnN���o>P�"�%d��U�kE��~��mO� ��T�۳�j�?\Oت�5ԫ�/W���as�	�8�VX��pw�mT�&�%����w=��;���.�����ɤ�b�'��o�Ä�Rg��qBμ��a�$-�4�E�XY�1D���Z�!^R3MB �A��������
�c����N�T�#P�� bl����j1�~������M88<)ګ�~�?�uy+̏�p����*�;��g{�mF��i)��\�a$�_T2�GD���g�PfT`/�3�t@��|/�c�?�{l/*H:im�ʒ	P�9�bV�A<��t@�hB~�} ��	�gr*s(�LX��g��:0�H�tL/�+Q�F@=�����J/#�xr|��Y��p����^����j����I��5�����u��D� ,M����:<))B��]����_�4�s���|}�J�p��#��������4<�j�,BA�kg- �M�������sڥ��0O\xǂja�(׎�/�s���,��"h��0X} F�Q1B���*�!5*���s�`���+��a(@	�̨������x���8���2O ���BG�,Rl<*�g^M7��8�.� �+�bϐ�z�~�i$޼�M����r�e7�Z��B�N�A�>m����A���*���4������)1	X�3���i��6�)ihL"��D�>��@����z��Q{��� �����8�	�Nѳ��ni+U�Q(^m$�:wS� R˄�|�t�Gb.��=�ճ����V��f\ui2��Y�"ڝ�Y<�w�a���ᨆ�=�D�U����X��h�6�.���C�䖃k�����UL(0	D�j(�}�>#ͳ~9<���>y*�|�p<7�^����5���9�3��mԁp��c�1�2����z�P��1��x/���nu�E�7��l��$�w��ZV��0�c��`~6ԥk'�۳O]����-��a��
<�����$��yFԨW����g쒟 �5_�|�Pq,���U,��M2�^�l��{�v1��<8�K���
B�� V�\�O��Jr,��^�K3^r�9�`�N���ג ��8���*�n6r+,\����Wz��c7�}�q�4Ho� G��XX3`��\���z,T�u? i�Rȁ�1R-V���U3�\@#Sm�M��/H�@�掋�!t�]����d0��ւy�xw3L��C�rQjhZ����:�?O�tE
[t�-�Y�����qE!���/���gE�5��0Hq�^���XN�] ��� SR�<��W�e�GV���J�JG��J���鳜	�]�G���g��LE���K����M����xF�Q�i�I��h\UT�[�Ӆ2J�nV��VS�<�u���L}9h0���	'�?h�>`��䃲��n��b�V�Ih8�!`G��otXm�d�񝍵e>#��l��zd+�d��A�,ٝ�;�/�/���s�Av��<렶�p��l():����������7*�^�wL�p�B�����)8���+�1���U�6a��V�&�>��a�W�QY�;�i�߭�@��|�ȀU��6\�[Z�t9D�IlX��.F��y��gY�9�*������z-Y�5�S�Й5��\,�9j R.gt�T'�%p�LCgS�Y��l��k��vM�����z�N�8���8j����-L��ּ�m5���L��#B!���-�7ZC	���K�KU�8��;���خ�Q	\��vyWFy��DCZ]zPB)�`Vo�/6���v���`��Ӟ0+�-��r���_�k�, QOҘ�:$B-�ګ�Z��ȡK(�=��Vù��;�^��B�gg��7�"�?�m�G�h|RpK:^�2Ir2��䙤��K��Eҗ���$�as����P�]���U��1RΓ<�4���^�0bp�'�fJ��ݝ����:�$��wh��:?|V[箯.I�O�xm��Y�:7Z��_��x0]�1w-_쇗�U�t�)��yj6��eZ�ys�
(�zA�8�)�.� ��_"i�t:+�R��g�JY.^�֜.�B9� $����>9ϖ��"��u���K�PF������r�Y�\��`d���4ݩ��esS�}!η�2���=a�,����rʩ��|�%�.��&&��n5CS�Fv}� >|���1�"s&*�tADޙ���D�����|L�P,�#����Q{��j�G��K��1s��+���zq���|P�Bj��/X;���2���0�մ�O��'��OF8q��:M8�=�4w�YҔ����*@���]����c�W��D}���}D��}5q�F��o�C)�?GHyX{iœ���;3{[�ʗ��&c8���4��'�'
����v�H������-�T�}(�{;|<�sb��z� ����ΊP�Z��	
a��
�7�5�3m2G+5}��'�Ι���6��{��(��3�����Ԭx�̓���@!��h���Z�?�4>�      G      x�M��r�ȒE��W��^1pZj�RCJ-�3���&H�HA��������6+�2�$�~��;���W���;v���8���1Ծ�|t��q]�Ϫ�������Y�G��.���ͥ�*w��x=��)��<�`Ϣ��4�խ�B���x=r���q]���j=�ݮ�w�"^��ƹZ_j%�-�d���GMW�]�L�$�V� 4E�rV�$q�F�n����~��(I�$c���E+�R*~��I�Σ�Q���4�������ay2���=1���>Jfq2��\�o���U�������=T�����E�,��Ǟ�ٲ�2N'��r*�zW��N�t� �����[��H����/��ɝ���)J�8�0���}�PGi�y��}�$�|p�W���y�N�{W{W�<�m�N㔓����9;�t����G��~:��Q���۾p����E�.9�P���s�����8���[l�^�%�&q�Dw��fi��%q�F�n`�C��U��O��Uj�*�6��,�V��?K�1z�>�O>��8�Fo��y�KN�<$���,z�M��w|��7���l�w�=�krig��
_����xl�lg��gY�&��G�=D�2�'xLUh'+��(��y�:�P6wmXF��$�����j�c�p��4�3nV���@��qY��}x�rb%�.j����E�V�y�O������}YלG>��Yt����q�г�|�6e]���WM��|�ܳ���h}�q��n�eUVV��|O'���׻~���x�D�)�o_؛����V}��'�8[>��R1rQ6�o<�J�-k�x�j�i�="�Ǹ��m���[��tƺ9ާ���,fO笢��I+��� L�K���k���tI����ܡ �It�)w����~��r��,a�sZӝ�l8t`�F�x/�q��aU!-�e�5|�l\+%������S_p�V��̤�+�R��s�xD+;|��[��l�l�4=����0�$�5D�nn�]ĳ�"r窲���a�7��a>��8�C��ɐ4̑�9�� Q��,��y����y��־�����gY������ܺ�ۿ�R�<�O����]��<Y�0�iA��w+�Da>�n�Ќ	��l3�0_��xں/
�%-��2�Q��{�|�J��N�Amw-�	�D��=*��
�$^��޵�U�����������m��(�"g��G�-V�B����5�&��Ǳ�~=�3��G�� Τ,�x1�fu˩=�Kb�#�[LAK�T�⡸��א�Ta9Q���G�fKP�%n���޴�F��*,S�嚁0?��UXf���k�� EX���~��>ybC�����_��0OD���?����9�Qf!
K��c�����[�ܶ�����}�}��!vh�rIBޔڕ�gɕM'�a�#Ş�	Q�d�D�6����q��I�;q8\�<�Ҥ�I6R�Lb�n��r���19%���������2p@f��-��;�K�$�N���+96>*���u�|K����u�D�u�J�c�������HZF���+�DK��|����?��B1�t�~�`� �Qbyc�0Ec� *<�-�t$��u�
�Ϫ;D��
���O���
�ºܘb�%+6Z� /����,ֆ�$!�.�bⲮܠ�E���Ճlj�
�<$@��	����!)R�dx(�%:�LC��E�n�DuH��7�m����aWj	i2��3��x�);<uH҅	��˿��"�x�	ɳ��H�D����<��A=�H���~�ww���H`8� �_����L@�yñ����佶�H`��GrD2��h$w��LID8��9��H�	԰�0䎻��$	� /U�5��"��>(��
O�!��B;o��HB���c�׈�Z���N$��1~��0*� DR�aޝ�D�
7T��-��	��@��(D��$l@�Bkixj�$".��Z@�7��$".
aF�v� ��@��zJ(�����Qu��H�l���@wd��/N8�
R>!�E�XJ������w�H-����@����o��D�xE�ऻ�(5�ĩ������:H0 ��Z;,k׵��QzL<��@,�%V���3(*�k&ao��xi�Y�d�x.tkO��;��bG��a�*$�ě��c��|a<� ��=�*P[i8q�!��U3�m����N��8��';�$CXKX��H��V�J�2��(�H3��G���)�|	$�\$r��3��x�d�,svZ�����p�?L*`�u	�#����k�`jL(���w��E�^���n���r�f)@�/�`@K%U�ުDlL1`
6�c�t��,�ň:N��XĮ��U�l;cx�+(�_*�$ �wߐ�O�%��BU�CN�dD!�6� +�������$ca�T����c�bU�
������d �^��3]�(�²"�Ijq��`ʱ�Z�g_����4��.n���з�ip�:�����	dq,]��V�m��+�%-�@e9i�r:r'���e�]k�_�TJ��$4�l��39�E{t��
�����X�ԅ�|(B��/�P��Bo�ci� (F
]��*��Ζbw"T�^��~���kh�N�Pś<l�U{rk���� �����J'R��_H��e��B�J�^<�/���C*A�X
^ �+��b�S�����}
߉�^�
��N���;I���3�W)/`o������Ѝ41(��y�{�K!)�1*6������v�Ǜ����G�w��#M,�H;A7�Jp゜�a����a۸w���W14�24$�<���/N
�H���A
��g��8���E�8��mt���vNjS�Z��� ���Q�"J5�KY��S �Cm��,�V�`�A�p�PkT�+ʊ�U�~�u�*��
��֍�`�u,*� ]6x����5�P�\(��!i6��|27R��xV _U�% )�a�o����P�%�T"c�X�(xC[�a��%�2�Ha�W��l=��Qރ�����R���Ѡ")�q=֩/�W��E
w�p[=��4t�*5-|EŲr'o��B�#%��{#��x@e-����ܸ��FWh�V��b�w�����퇔B%�Ík}�d" )�q���H��X�"�:�}s*��H��<eܑ��q�(_VҏT�A�;�r��R���H
}�w�w���J,�=�aQĊ*�$�xt�2����QC��k��~�,#�r1S�>Tw�U�q)�}C�Û4�YfݲR�ҩ��4h����r�^u8��Z�J*����D�P�̫���E'0
�`M���Fe=6�/�>w�>M8 �����:TϿ�rc��T�a8�mY��3嘙Y�t��w8J;fji���ŝ�_���<��ʓ�M?`��	VPg�f�DJ5���Z
V��c�ҿ���Y6J��G_m���w{��T�Z
s
���"	Q3���� ���:�/�u�:�@��o��δ���� �4g�@��GuԖ�k2�� !���Ek^ksι]���G��U�ǽ?R��Ş�mR����1��ܟ�`��JH���d�W��c ��JL��z�&�`�K
�\"d�[RL�H�]��;&��� #+��Z�D�Q	S:�P�m~��%"�Ⱥ�
�T2	�C.~{���`(�B�{w�s�P��L�������Yi	��ԑ] l�A͹���&2�'K;8y�ELgM,�G�����T"Pi	0�@�����$K�J��D�F��T���8vf���H��k�-U<A��ԠV���w�b����̋�z���d`��J�VkX� ���Z;�Ղ��Y.)�q��P}��<���ݏ���
�,Po" r��?��W�g�Ź.2ס���Ja���~%ڑCu�G���1
��A���w_�`$j���^��&T
D=2�cl�KnoK��F@2��5��·�� 6��q�F~��6�DDX}:kڡ�1�6o��G7�D��U�7��)%�s���G�ܡ5#K�ih�v:a,��w�`��K �  12����Tr~�m�Gp�TC�V>>��q/X#)����=��yLi��jd����>)��L;�ꄖ�J���֫&e;�F$�#���|��}���8v�d�b�]7�Fy��+x����M�X�����R�*BY���% �tNl{�=.�(��C�㣯@%#���b��f��GW��o���~�@ɰ=��01�r�Q	�[g4Sӣ/�8V��`��(Rbku�_�#�a��sm�,�A��~�r��ĄH�"/��� ����wŵ$��T#�B��:Q�n�#BC#M�t	����c��B�P��&�-?}�$�nd��u8��[�{�)Gyh����kg�P	�T���U��&]tc�4A@X��k#�@$%J�+wN;\���k���̃C47RC�<�l%#�(�����o�`�ˠA�ґ�,4 9��WnS�sL�*�5�4N馷��> DN���-�lmL̃C��<c6fT�b4Bf�.�uG1�쉍;b��L5C.�n����$ �YVj�ݨ���Z�o��F�m���~���#U�%0�����o�,�c�HT�`NI	�16���FJ��ce-��q��A���MUS܍�K}<7�adS@���\�{7��F
pKf޸�4��1L���h�ƴvi}<������&���r~S�uTKG@���FW����3/a���E�Y[z�#��,������6���i��&�N<,	<���_�ۖ�1�P����.�Ӎ�i��(8k��nT �R��d�%�N��,�.�9[�iʅ�p�E���h�P�؅h� E(6���-vM������3� �~�+�$&@�Mm�U1a�f��P�)����`��8�zo��ܔ� !��:�W�hb�a��$h\�1&��"߬���[��`��QKy����X�ܫ���]ªB��b�)��K7�dy}��D|���� !�ᐿ��Q )��zz~_��ꄵ\ʬƭmhT�=�5kQ�����ȌkS5�
�nO�(�!��Ro�Ǎj�%�Nw%�˗���P��|�(t�R�4�B�MR	@=p[�#�Cn�GN�^�HAd�YyrtT����	�D~�X_ ��!����:2�����QQÁ�#!9,��٥O���R��Q2�'*���Aۂ��� �׾*��^�D�FM4E���Ywj����>$F.U>"��#�D~�ˎ%>���>�A�5����<�!��S�����#O�B_Q<S	K��Y����~��V7� 䭷���?^�S8�y�7f�"�8�Ŝ�<Ã�$#O���3V��Ts2����DzR�bر.wz_� �9V@�%�06J�>�P���el�9.ڽ,��?�����+pȗMo9��3!�b��IP�氮���O*�oަ�j��.9��4�+�ǑKv��*�J�j����"�5h�jԔ6��s�T�y����4"��>���4��^�@���U|�5��$h�Q���=��b�f-pm���������_�P���:��t�n|AC�iw���`� k���^��.��bUl�0d���:�\�����$#�Y1�E0j�|h�z�7U���n�V�u�U?�z����=j����y��S@�%�����ܸA�mڪ&�^��DGPu�q8�O�c���GM̛M�erI��_�$c��o�����7�Ѥz}C��i�ί��3�3���j�s�4��=,�� 1R�CM���xj��i>6>v�?R���iܱ6�$p\��+,%3�-��R�'�
!�Y��+n�O�1�X����m�
C�y�[��ᡕ&A��r9F����ɡ�kXQlS9��d.-iԹ��'')���U|��oW�$��� "؋�lKG�z�;Ʒ���m�(���� �\]�f���[&lt)AY(?k�>TIP��*Z���mo��<��ث+��-I�@�*������ʵz�k�pr���e���{������bf�)�2��0��7���V{!EY,��0L��xh��/{�+�H�o����j&_j��?�BK��L�=��4i�4�������F��foz�B�v�~���: �^�5Ss���+@��Y?�nǷ=r��Q��O�O�Q0 �;���aT���o��f|l�M�Z���a`�W�&F�2�Ww�w�����8���Z �      :   �  x�UTKs�F>w�
�rA)���a�5d7�ݽ�2�6��h��%%��mIvʹ����j2xl[[ճ��,�IN��5��d��)$;��lL�'�}�%<��~��9<H���ΒKkI�g�6Fr��-���ct�θ������a'����sa��U��+�v�ewp���v���pmBc0����$�N��ґO�T5$�*���NLmZ�JX먟�s8E1
��.`O���#�g�)~	���4g�0=�nI}�1[��sNP^L�;�i��%kg�fT�d������*<��~����1����:/`kDȹ�X^����bg�s�i"�:��/4�M�EnH�*Ly|P�/�/�gɑ�����X�J��!ݓ�~ೂ?;_Y�>���xacDgbq_x�������>��,���Z,r8v:A^X.�O�B�E1�3K�Xs���-)ʏ�3Qc�b�j�swՊ>t/��6S�N�F�X�s�5���g&w��k��K�5Kvܓ�rjؘ��m
��xL�X����Sf�7SqU������w�c0����Ĥ�[{�Xfp����ʔ9l���=vt �X�W�{,8p�c�|�өG�ja�,�5���b9������YM�yc���#^_;���߻�Oc����;{��1�������f�+MV+9��u��_S4����h�����h_       C      x�U��v�Jҭ��SxvFu�ؠ��d5�Jұ˵�$I��4A��F4�����>w����]D�Mj��Ʒ.������Y�ܿ���>��7�ytUW��m�V�
�"�,�PE����&q��pe�\t^w]��$�K�Mt�������эo\YD7�X�I��5_�-��W���&yt�+�/���h7u5��D/_4a�ԌS�~2�FϛД~���s�d�|��.:�����ov��ܯn�0�.�{_�*��*׮6�i��Et��j�z2M������N�ڍ;L�it�]_j2Y�2�u=�r�>���4g�ʰ��W��dv��Ux��h5�d6eSZ<�q��l����e��a2�Ga�f`,�r2[D��Z�P���>�ż�<��}^��Y�Uض����{�t���}h8Ō����}�kΣ/�[z׳P�lY�d~�PM�y�����4:kB��}[?L���C]����|ξU?�����7�)�C��.����ԇ7��������~2O��ox��6�)��<�nJ1T���N+�g�AX3��W.�]=�*VN'ѵo����rٰ�~�`�Q����f���b�6]���%��j�S\�u,��k5���w��"��V{�'���3�����U�Z0u�uu��E:s�ih���O7�w7����"�r}yw��-�+1�<T,�_����x]ԃ3E�cf͹��ߝ+|�d1�xθu�cL_q�"z��Kl�ѭ����qt�mǷ����	[Ķb����������Vgl'/0��G��u��>px��$'R��cDO���!1��:�p�%u�d��v�sf7	��u�whڝ,�SLX�x^��$��JS�~�`,�t]�k�С.���L���Z6�R7����v�`�XV�*5��3��=a����Nғ��MY�$��Rl	��Ε�z���t�f8��>�[�}L�CM��a`)nN^/���D1��FM�I�hO
���=��Y�T_Fc؇2��$e�kY#O����[�,���u5M��d'����.�h�$�FM9`��v�͢/oh�U]f����5���W���I��nz���W��d1ν0��q[�.�I�H�vR�z��X�Ꜧ��ޤ�Y�-^mL���g��� 3�U�\���r��G2Ũ�聓��I�oކ=�Q�}�����7^:�����N9Fވ��$���x%�+۶�M`�'y}.}߰se!����IU��=�u^�;�J�ə��ok�b��=�q"��:��5���5LO���XdY.���3�[W������\'���G���mR4�<`v���ko�%q�zI���t��+�{�l���#D�E�a����ٿC������󞕱8�P�0T��-#���x��0=N���_X ٹ+�{�/=g?#��5�h�(�R���.����n0UV�H���h�*����d�����^lX`y����'�q��''tV�U��
,G����U)��=�I��{��|���6���^�<1�cэ��7м��]39��f�V�Kfx����ə�5rvB��,5����.��������N�0������G_�
��cu��6�<]��Ԙ�����rWWE���rS �^Jw��鈢��-��ZS0T*^`�[}c���z� I���._�+^oFst�m�Ǿ��7� +���&���D}�cpw���ָ3N~�����^p꟱@u�[��6~�ЈA��%��"���9���<�L<}�8H�c {���;iÅ?"M�TvG|�Iq��u�ؓ�	��/nİ��_&p[4T�g�8:#lS�G��❃ڝ�����}��y��~���玭��#�G���kY(��@i<��b
�~f�+ߢ�g�z�G��!���$IM�哯�qRW��x-=X�����D4nP�W��)��T�cXm�=ɦ�]�
#>_x�A��?�P����_<Ā��E͑���H � �ܽb_�����6Vb�y��=����
нb|��yt��E���;7�g�H�ę*F7Ȁ-�)���:�\H8��j`���7x
�|��r��1��C����P|� e�;�p�"�]�3%�xSk�oO�#P2�}�� �8�S�dY����&T[~�?t�8�zݚ����9 p�6&1k1���[�$Q�f%(~}��� -�٣(^���if��P��15@����Rz�oD�d�����!2c=����OD�o�ڢ^4�o�֗�����;�v��Im��N��_=uU��@L�d�D�s��s��Z;�@!�zs�TL�g��3��P�o3���4���ݛyc���_�,�s��wB�)0��ڿ���}bod>3��.��a�[��0�E�7R��2�<�?+���+8�0��(��CH�A�	s)
����	{,q�C���/Œ�:���݂P�+��
u�߷6z�i�_�� �{�C��`�|�2��Ҡ�{.�6���9��T`ހ�:�P��@�Q$bރ���{'�ٽ������,�D���-s����Dw��q6Ux�|�֯��f��щ�����l62|Hq�� �¢D����#1�̈́]���n�@�&t��^��z�,n�`��L�����0�����Ql���e) 3�T�~k�AFb�y��[�չ܆�ʼQ�=����M���,��� C��PԌ�Fl�����ނ���N1g�p<�,w�oǌ� �UFC�o1ߙ���-1�B�ex�7��U�33{+�+2 hk-��d�Df ��|��:{��G%v���Yo&u�z���X(���9���X��1>�K�ʞׅ��vc��R�n'��]�#c�a"�a BB� tx�5cjt}b�:+�_%z�pz|5�lL��@K�� O K�.`�JG �_���kcxP��+�+��|ظW;3 �[h�A��C�$K�;���^lx�wH����t�2A�1�ˌx=�'�޷���������Q"�µc��ϒ��#I���c�P�����i�D��:��8?{D<�(o+P�!J������7��q�%�$�pl�뺚]^G�|�P�c�إ��Eb�!Cӕ��'[�V�%����v�*����4DM1ҭ��cC�߇�~�f�(Ă�6�­���G��g�n��� Ư�̨�`�ﺒ��?z��N���\oJ9A0�I��%�Z ��LH%�):�1i��k��ZJ ˱d��N(P2�/�t�� �{��^��K��>/���b�eu�[�,���Ƿ-͎:��v�g@�K�)����Խ��U��"��4m������J3��zL�5��5��|�{��:���)xZߚ���4#�k�
<�����-�q��jk��w��B���Ō#�h���3s���q�,��l����Q����i�>� �?���F7������#m�~a�,a�/����6�0e�{ϵ�)��܀7t�,�}֕}s@��+F
��#ȣ˵(4X��90|ոa�-I�e�Oe�x�U������4��sP���{�\��s�ً�i� �o�Xu�e���~c��#ސ��#�}*��T~��v��;���Ȯ��� ="�R���� 0,��l��t�x��Ap�V���-����@�`�`�mp%z�l���*%oZe�Ρ��ı�+D��|�r�%��B��,�J3%�J���o&�M8WJ����E_0�j�v�'���9eף۾� ���"�9�����?(����9�3�3_Jb,h��0�GEm���&'�r����9`|�}{�Ԡ��s�C��e� �����q�Xf`���ei����Vs����B���FX�@�1/T`mTn"�������ea�+
�m:�,���1=� �}᪟��g!.ZYh��i�
!s��8�! �uo��~��%R�@�si�"_ �(�Rr�����ˁ����/s���������p`2HՅ��>Ld�ljP�aɔy,�Z��*�D��f�%���r���ևv��?G�7�Ri�gv]ps�Qq ��"84*��Ts��N����������|    �tk���!��� ���p��.����d��>�Jy"�q����ѿ5_$�*1"��G��9���^q'u��d
d�0gdA�]hi_v�6&�f>��K8��'��|z�nX^W>3���V7x��J��̵��J�1,l>S*�~uY2S���^ϬH�e�nL���ʏ��N�µ�rv5$�!�S�DU"}*����(ki�z�#aǍ�(�n��"�mM�R��&?9�jNF� �A�&��+��JX�ZYL̢y��X�@�X{Pv�}�D���[�⩯%��ҍ�s�,���
 0`�X�r-���߽*b��J4�̢�;� �A��sP��7;i�^,iI���9 |�W����\LZ�6⛔	 �d�l��R��p��$EH� 5Y��#�.�1���2����7�� �m��X�����XpRD򷘸�P��}��BݡoQ}�1�{���29Vok�塑�ZK���X���9��<�Q7[���������̔�(do��ʈ�	��o�=���eR �^(� k�{�Ŋx��"#��?�C�JeƱ=��Ȓ�ЈG
u��-@����ޯ6J;"���af�+q:�RpS��b���
�5�kZՈ������{�\T�m��B
������H?;�\�����4�]=[~���W�;S����������Q��4ᣈ�3�2BWk�b)�� pGB�t�[�����p8���RY���_~D�|pn���kl��

��B�4�w�V�9TxDq����p�}%�� t��JKcm��0Wi��Q�FH���A��NϮ8p��l5xb��-�5Hw�eMU�U-����,�{+v����5"�qY	�`�Y W�%$XG��/�09�U��P�K��6�kǹP����x^<;zk%f����A�;�qO�������w�"X�����f�?�Cu�h6��06b�R/�U�aDXp���P?���ZT�݋U��%LBH� d�j�Q�Z�h�.�b
U���%���ǜPͼ'�u,e)ct1R2��e���,�VV�En��#h����V+F?��B�JL�RH��9ţ����vC\� _/���`��F��h�u�;�e�&���
��u�(�_��z���W>�@f�w@ׯ5�ުފM`�M-��6�I�P�V�1�ec���˯�շ�Z��t����@A���8f)�ê�d�"�٫/b��_�.���*�^ι6��hc
����s�ެ]`z�l"H�;(<\d��/,����¹X��?m��,�گ��vǆ=[Y�Y�>P�no�ҽ*V�
��m����9m1�{�)�a�^*��c��k<��3G)���V��^����"��y��wd�ފ���|~̃?T%�@
̅���W�)�� w��:X+�A��]/�6�G�B-��n�8cɔ9}�w4�g���j���
*���"?1�{��i�@#>1�'��%3���6K���.����^mh�-� ���{�Z�I}QLу�:��D�ѐV���_ƪ���U�0������ (��n"�8xí�b6aي}"�8(�:f 7�v�^V�P�g�q��1߯��: ����q˽k��ZD ��.Xn�٫+)V���Y�AY ��T���|�Tv�>���c��V�������m(�@♺^v�`�bgk�2 ���a�g"�;g�+A�k�����d�A�ϔ/Q8k�j<���^牳!Ў��;.Wg����5t�J���MnQ�j;��ce�Uu6f�Z�eU��t�Y?W�^��<�H6V�T�:�?]U�>=n<�.4�3N���*.՜V���S\��kW��rQ%e'c@����Wv��,�[��K���Z����*�c���⎊�_m9 �l=v'���w���
�RQ��F�lF�L^؎B�z�y+�-��s��(mq�WWCt���o��U8��#�F�}�0w��h
�?�Z��Kw	�:�udD�,A^5�`Y;�+��<�	��7Y؅���v�J��q���'����1��uk�W[U��-�@�SY��WH����}���P�I�(<���jX�VbQV�E寐��R�T��.�~2�@IJ;z#XXU����5c����S�վ��QYwc\�G�`�^�4b�7���!ɀ��r�0��!U*���l�'ce3X\Z�W��H�j��"m��~i�LA���ߐ̣���d�y�~�Z�.�Z�B3tA|�|ZG���HչV[6^ ;F�b�w�A�s��3���U'/T��Dr��"�������1F���ȋ��ʽ�0�;v����Š��8D%D�6u�g�J2��Sa�|{t�Z���e�$�X��9�鈭ܢ��Q	=���/�z%b��*UZ�<��R}�	k5�I�U4���a�J�ea�1����h��z�?����d| ��E��������v]{�ǯ�r��:0pN=����ß�?�(|�.}.���	�b!�����b ��Z7�vt۸�n��X�@�()�DeհO|�df�t���rrb-&J@�.
���}�2�M��W���߇1/h��ɉ�j`�=�Q���1��ꫝ|���� ��J����(__���&	@̸cc�F{	H|[�q�G�4N�� �(A�tn����lwc[�ْ�Am	��8�!k�tM��&���s6;������\N,���PtӢ�v뛱�)���mBb۠��̭��w�*�������],�i�T�9(Q6�/�����p��Bȟ*�XG�X���pƺw��K,t�����!��F]Պ��5�A>R�O*��k<+"L�����g,������j�^�e��9�7������I��D�_N��e��Fո���V!�\�L�v�_� ���p���	q\X���H���0�5��K���I+��p*��u�~7����; _ֈ���J����j��?7���L�b��Z�3�m�"6z@������$�O9�X�A�"���B�PZ�Ü�1����p��j�I�`�F�r�D�f+a;;�̶V��X�Y��>�]��	��Y�g�-�W�=�u,���s��!���3�"9&���=��
ۭ�
��8��ڲ?;}8��
�jD��LTB�S�.����ٴ��MN��hw^�'�ou4��4��L���P�1D��j���i�U/e�E��h#0�4J�����&@��V���a�r��'LR��)���U{~�mb"5�Sa��"�S8X��M�Wb?w5�+"�L��X»��$�xB�+�&���cO��Zz$5���џrD�*��I��4��q毯�dQ��)��m��ŠZB9�F�,�M�*�dv@!��^K��T�7�Ks��6�ey��q犲���=�{!�JS�=��r��Bg�R�h��*F����,��nݨi&��8����׹��M���Ӽ���Q�;��G�&��_o�7� %܅�)��SJ�T)WW����U�J�n�����͉��<^��P�ϳ��4/�Y��
x!.(���M_MR�V�Q_ˁ�ӏ��'�x�'j�����o�����VE,-,jT����z*6N5p5Aq��	4�l�VZO��oJb���rLV��s�{m��=�o��s��~h��t:&�pP[<e
���ք$���3��.��O-�M�E*����x�����轊�5�� #ʅ����E�$9f��_� P/k�A�����W��-\�n�)ez��H5V��\�0�|*DU\n�~m�r��S����2V����Z�p�2�L����x�PR���_����(�*�\[C8��8:��!�O�K;Eb���"��z�&��F�`��) �������?���K�~TG�0�eX+�|to�*5���_o`&���}�&��oJ�[����N��+�rΪ�;��L��Xkgw[�s�b�/�u�m�D���{�ͽ�6*�������ux��15�1`��̢Su2�nl�IӅ�t[/�ˁ�K�T�#RhW1�܁�T]>e�C��a�*���_ۦY>�j����:�Vb5�<���K�TO�^�]>���W[�.� /
  {ja�0^���ZLUׂ�[��������x�T�;�:c �z4|Y��!�-J��eiY��Bv|��O�*����a��~���3SU'���b'���p
�R������U�UzM)u�a���#�]�Q	��J�S���������{�N>C	����H������G��e��Ű���<�.;E���^kH���F����"tm��?�ÿ��S��tvlKW���:��dgi���\��L��u���¯3����}�"Ӿ�%AS�i��V�pC\�H�c�oe���逩�A)����5OO�仉�eB|4UG� �*���f�C��/�gI������	���(�DV���lt�l�o%�D�[�P�+����,S~��R�YWD��]e���B��o�@��]�z�tJ��"�L�ԫ <�}	@��`cf�@E�� �X��%�cSzә��C�pH���P��K�.`��8dj�S���V�Mu�Hm^V�66���xĮD�6�<�N�o���G6Z����,K�e��c���e��݆��س�B.�V��!��D]/b���v:3m�wj|wO?�f����7���\�^�U�'�[W&�B�gb+h�$��XF��h��T���.�K�dv� �n���U�	��U�D6]��+�
�Д)�������3ɟb>�Ekj}�n�(CĐE��"�Zb_^��j�l�T�MC\]�;� \��1Dȏ��fSK{e��v��}��J;#�W<sk� ���}���f�>7��b��c7SGs�����`�F�����N��׍I���Y"W�X[�d&��1��͟9�k���֓Lg�����B�5�ѹR#?z��Dc��z`Pp�BQ��۬k��so�M�C��Js�������mu�8��d�m�;�Ϫ;�j�#脏�|,�
+3��9���J�!��I_=�Wu�� �rh�2_�?��1t��HS��"U��0^�d
m�0���%� hO��!���f�tlF���t�j�y�t2��?2Sʷ3�����X��α0ky�LW�P�pLe ��ߪ�*�J����@��Y���(��xۋ��Y+�<��q��J���W�^^�c�r&�ݫh&(�d���vk�'�*e`���4�SA��Mu�^�X�����.�W�sH���6�'�]�lɥ ���)	>�TJmoJ���_;S��՝S��%R����wf�Q�C��T����2���Jp�:��f�n���F�tC�b�^��tf�V�m¢���r�0�S����~�+��3�\���}�?f �ʾ�]�"`�=��rE�oԙ�;� �]?^)�|�)�K�s�G�ՂXkX��	��+���,�_��8�Y�^#aRY=0���H�>��Z�\�+3SJYQ(ʡ�E�*�?X:��(1�	p]���+�G��R/����E��}���P�w���{5z���u�Y�Y��yU�[j}
cǪ�]��Վ��6�]�~_|���$�blK���d^N��XR�U�e�\\M�"�P�4  ��c�ë���LlC~��s  �y��-4Y���{ʚ�0���'��j����ؽP��.�y�AD�蟺�w�B8f]K�7^	S��h9��q�z3�e���������DͲ�.�s��̌��/,�S��;�ݺ7\��[��<�
�ñ�����Sój�p��ә]�����[]9H�gT��r�t��W���g������(�ۘ�bL>U㋮���]��B�uP��2y�V�5D8J/uqc�s٫i4m�`(a�^����/�Y4�� ��B�&Cax��fʣ�642f�=�*K��sPV�xG���o�gcf �Qs�g�7/~6�9W�XR~�0r��.X.X]S� 2�Y
M����ϏI�Vw��+���u:�k�4���g�ˮ���_9��<TZ�
9�z�R�e[��H�2�x͓�z֏W��H��@듕���Q��"�R�؍����5	I'��T��j=�����#��
H��F"��Wj�F�z��󛃭7P�0��������FA��b�H�\���א)N�l�E��d���r��RX���t���7W�O����{��%���".���>l��L���TY�V��+�x�;�@���O�<��sA��YF�}�#MT6�SKa�̿9�v����m5�����Ũ�ĝھ'��Ƅ(��k[��\p+�7�W�A�kݗۺ���ȵ�c�%�۫��b̓���I 1��6@��|Y��R��tE�?����zDs�>4�E��ޢ�н���� �ӏ�ۖȨ\2Q0��P��W4��_��_�NUM�D���=�=�yt57��A��yj5C��A���v=U��	2��Z_sP��o���[������^�(ɔg�9��r]r��hճ�E�cu/F����W�D���y�Ҳߠ�u�d���ڃ!Yp����� �r���2e|L��u�>�2�i�zc���j���鏸(��Iy�A��A1s�� Oxfe|&��R6QY/�;�C����J
����w�*yri;t�*z5ޑ�N5���\jg�W:T��3J���h�C�rm�����O�5{R��Ɓ����k'<�W5xvI���L&��`�%�      8   =	  x�m�[��6D�[�	ć^���)��3.7ƨm�%�H]��O�Z��G��R�c���v]�ȟ��W������w���{/������?���Ⱦ�e<⑯]����k^̲q�W��"��b|��>��ǈ�'���K�F��=­_�kĊ�C����O�q��"�q"���"���z�g���j��,��A�x�*ZI4qQT�=U⢨�H��آϩ?�Q+�I�o��V/�(6������ǯ��^tP*��:��O��|:���=���K���j1����RL�_�b3d�=�T�¬��{,�����=�-�֊uʝ��z���Rk�&eb�c�k�O[�+/�k��Zb�Jq����7��F���`�S-���-ӌ�����{�A�k�G�IY��8k ת�UZ�خ�i�4^��R�RОl�ysP�Z���`#5kb�u��H�^��o��i�Ƌ  5K[��c�^I�P��Q>�"�+�%q��n�4�{�tF�r��F'$�tZ���� ��=��I�|���G�zFV��I��D
����?)�(j�{�'E���p�0����� 
Ǡ��A�`��±~�)P8y	X@�����[�H�J�hlU@�4�G�
�ӗ�A�ltO��@�dx�Lv-�K0)CƳ�EOk1�����
��R�R�E@�2����@��<�{��F�7f(\̂�k�Ҏ�GY��q��EQ�{�5��<��P��aM0����j����.�Qu��5��H#R�
�7����Qvd)�Q��N"x��*�5q���m�+T��
�8� �V4P�$j��m�ӡ�.6��B
���3hAF�r�m��H���Q����*
�"9��~Y)���5v0(���,���H���]��hgs�j�1�"B��\7���"3x�����c��b���R�k&;�3
#�,Ŝ2*�5�|�q�B������a�b��@A���X�P�y�H�A�d�Wڋだ��AR�r��B�4}P�_�TA�SG�P.�~�2�)��� $Ԁ�$BF�P�����nó	�+-F��״�Ҍ�Q��x�YR��MFm!Z�j�:���t�d(�F��zm;�sE�mxv�A�.�;���g�B=�R�VZV�����,�w��٣�5v甈����Y�C��h���@�1x?7<���b[�����~�s��̨���h\����I�T�2����j�ɫ;.��X�b"�1+egbjL΍�mxN�Y>5���<�oxN6i(���32j�sv&d�jLv���݀a5���𜋛3�p��*eT�͆�*������3m�Xψp�s�͈���\��m�u��$J��5�|�X��&�w?jq� �k7�X��੕��`�k�l"a����F��b�J�il�?��abH:O��3:����Y{�^�ɴ��-'�.=��Ws2+e� ����N����<Um�z���y��{	)�K��,�S�<���b��2��S�<�ۜ��\�<��W���E�5�U�Р�:�Mw�R=�<U�M'�>W�$J�ݫT�N��PC_%z\@�d��q�j����SM)��>�ݴ�$��0���P��M�j��S��H	5�MF� �S��Vd/��<�|P�Y�l�A�E�w�S��Wz�p���:���ι�x*�/�a <�'9���U�F�5W%1��M�I �(}�9��f��i�8��lcj�j5����Ԗ:ڸ�#���W+3�2Th�-$��v�Z��gg�'lx�ڙ�ó�FE�й��ox��L��޹ʎ����f==M������w?e���`�.�B��nx�Z/����]Nٮ���$���hD�vz�:8/����+���c�َB�����G'�"�[�1�ˁ $Ԙ�u�v��u��q�t"dZY��v��.�1�>������=>y�sN^[7<'����W1�X��w5o��R6<��_5�SO�S71�7<7���	5�`�F�Pc�v�s��xZ�l����Un�%R0��r�F#F,�#Γ��ڸ�mW��ixK�iu�ڿ>v`�OA�v#�����	w��Cq���1T��	���i���yf��u��~����I���O��q;a@y���b��C�5^��ѩ <��<�.�g�Jh��<M���nj�P=�Ӕ}�}0d�}-==O������y��y�rj�92���j��g=e��k+9�4c\D;b���3d�]P��ϴ٧�ֹ)��gtѠ�MvhAc�A��>��/癕/�p^)~�vs�-��Ӝո���_5Z j8���4�x�<��Bg���>���BB�Js��[c�����SJ�u�-�     