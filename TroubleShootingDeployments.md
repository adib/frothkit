### Upgrading webapp projects from older version to latest developer preview. ###
Their are a number of changes between older versions of the sdk and the latest with regards to deployments. The best way to upgrade the project is to create a new web app using Xcode's project wizard, then move older sources to the new project.

If the older project must be used, the biggest issue is with environment variables in the Deploy Script build phase for the WebApp project. The script section between echo '=== BUILDING WEBAPP FOR DEPLOYMENT ====' must be changed to the following.

```
echo '===== BUILDING WEBAPP FOR DEPLOYMENT ====='
rsync -avvz -e "ssh -i ${FROTH_IDENTITY}" ${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.webApp root@${FROTH_HOST}:/var/froth/apps/${CONFIGURATION}
echo '========= DEPLOYMENT COMPLETE ============'
```

The older xcode environment variables wont work.

Also the Build Configuration's 'Other Linker Flags' (or OTHER\_LDFLAGS) should include the following.

```
-lm -ldl -lpthread -lssl -lcrypto -lnsl -lcrypt -lmysqlclient_r -lcom_err 
-lidn -lsasl2 -lresolv -llber-2.4 -lldap_r-2.4 -lgpg-error -lgcrypt -ltasn1 -lkeyutils -lgnutls 
-lkrb5support -lkrb5 -lgssapi_krb5 -lk5crypto -lcurl -lxml2 -lpcre -lz -lutil -lpython2.6 
-luuid -lrt -levent -lmemcached -Wl,-rpath=$ORIGIN
```

_Todo: More to come..._